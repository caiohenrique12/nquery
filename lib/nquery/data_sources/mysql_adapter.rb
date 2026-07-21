# frozen_string_literal: true

module Nquery
  module DataSources
    class MysqlAdapter < PostgresqlAdapter
      def execute_readonly(statement, timeout: 15, row_limit: 10_000)
        with_connection do |conn|
          rows = []
          columns = []
          duration = Benchmark.realtime do
            conn.transaction do
              conn.execute("SET SESSION TRANSACTION READ ONLY")
              result = conn.exec_query("#{statement.strip.sub(/;\s*\z/, '')} LIMIT #{row_limit.to_i}")
              columns = result.columns
              rows = result.rows
              raise ActiveRecord::Rollback
            end
          end
          { columns: columns, rows: rows, row_count: rows.size, duration_ms: (duration * 1000).round }
        end
      end
    end
  end
end
