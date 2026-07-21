# frozen_string_literal: true

require "benchmark"

module Nquery
  module DataSources
    class RailsAdapter < Adapter
      def tables
        connection.tables.reject { |t| t.start_with?("ar_", "nquery_") || t == "schema_migrations" }
      end

      def columns(table_name)
        connection.columns(table_name).map { |c| { name: c.name, type: c.type.to_s } }
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

      def connection
        ActiveRecord::Base.connection
      end

      def postgresql?
        connection.adapter_name.downcase.include?("postgres")
      end

      def sanitize_limit(statement, limit)
        stripped = statement.strip.sub(/;\s*\z/, "")
        "#{stripped} LIMIT #{limit.to_i}"
      end
    end
  end
end
