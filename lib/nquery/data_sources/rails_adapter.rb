# frozen_string_literal: true

require "benchmark"

module Nquery
  module DataSources
    class RailsAdapter < Adapter
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
        trailing_limit = %r{
          \sLIMIT\s+
          (?:
            \d+\s*,\s*\d+
            |
            \d+(?:\s+OFFSET\s+\d+)?
          )
          (?:\s+--[^\n]*)?
          \s*\z
        }ix

        if stripped.match?(trailing_limit)
          "SELECT * FROM ( #{stripped}\n) AS nquery_limited LIMIT #{cap}"
        else
          "#{stripped} LIMIT #{cap}"
        end
      end
    end
  end
end
