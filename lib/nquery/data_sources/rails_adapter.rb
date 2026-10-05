# frozen_string_literal: true

require "benchmark"

module Nquery
  module DataSources
    class RailsAdapter < Adapter
      TRAILING_ROW_LIMIT = %r{
        \sLIMIT\s+
        (?:
          \d+\s*,\s*(?<mysql_count>\d+)
          |
          (?<count>\d+)(?:\s+OFFSET\s+\d+)?
        )
        (?:\s+--[^\n]*)?
        \s*\z
      }ix
      private_constant :TRAILING_ROW_LIMIT

      def tables
        connection.tables.reject { |t| hidden_table?(t) }
      end

      def columns(table_name)
        connection.columns(table_name).map { |c| { name: c.name, type: c.type.to_s } }
      end

      def test_connection
        connection.exec_query("SELECT 1")
        true
      end

      def execute_readonly(statement, timeout: 15, row_limit: 10_000)
        rows = []
        columns = []
        duration = Benchmark.realtime do
          connection.transaction do
            connection.execute("SET TRANSACTION READ ONLY") if postgresql?
            result = connection.exec_query(sanitize_limit(statement, row_limit))
            columns = result.columns
            rows = result.rows
            raise ActiveRecord::Rollback
          end
        end
        { columns: columns, rows: rows, row_count: rows.size, duration_ms: (duration * 1000).round }
      end

      private

      def hidden_table?(table_name)
        return true if table_name.start_with?("ar_") || table_name == "schema_migrations"
        return false if table_name.start_with?("nquery_sample_")

        table_name.start_with?("nquery_")
      end

      def connection
        ActiveRecord::Base.connection
      end

      def postgresql?
        connection.adapter_name.downcase.include?("postgres")
      end

      def sanitize_limit(statement, limit)
        stripped = statement.strip.sub(/;\s*\z/, "")
        cap = limit.to_i
        match = trailing_row_limit(stripped)
        return "#{stripped}\nLIMIT #{cap}" unless match

        count_name, count = trailing_count(match)
        return stripped if count <= cap

        replace_trailing_count(stripped, match, count_name, cap)
      end

      def trailing_row_limit(statement)
        match = statement.match(TRAILING_ROW_LIMIT)
        return nil unless match
        return nil if limit_inside_line_comment?(statement, match)

        match
      end

      def trailing_count(match)
        name = match[:mysql_count] ? :mysql_count : :count
        [name, match[name].to_i]
      end

      def replace_trailing_count(statement, match, count_name, cap)
        start_at = match.begin(count_name)
        "#{statement[0...start_at]}#{cap}#{statement[match.end(count_name)..]}"
      end

      def limit_inside_line_comment?(statement, match)
        limit_at = match.begin(0)
        return false if statement[limit_at] == "\n"

        line_break = statement.rindex("\n", limit_at)
        prefix_start = line_break ? line_break + 1 : 0
        prefix = statement[prefix_start...limit_at]
        prefix = prefix.gsub(/'(?:''|[^'])*'/, "")
        prefix = prefix.gsub(/"(?:\\"|[^"])*"/, "")
        prefix = prefix.gsub(%r{/\*.*?\*/}, "")
        prefix.include?("--")
      end
    end
  end
end
