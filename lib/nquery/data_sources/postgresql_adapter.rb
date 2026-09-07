# frozen_string_literal: true

module Nquery
  module DataSources
    class PostgresqlAdapter < Adapter
      def tables
        with_connection { |conn| conn.tables }
      end

      def columns(table_name)
        with_connection do |conn|
          conn.columns(table_name).map { |c| { name: c.name, type: c.type.to_s } }
        end
      end

      def test_connection
        with_connection { |conn| conn.exec_query("SELECT 1") }
        true
      end

      def execute_readonly(statement, timeout: 15, row_limit: 10_000)
        with_connection do |conn|
          rows = []
          columns = []
          duration = Benchmark.realtime do
            conn.transaction do
              conn.execute("SET TRANSACTION READ ONLY")
              conn.execute("SET statement_timeout = '#{timeout.to_i}s'")
              result = conn.exec_query("#{statement.strip.sub(/;\s*\z/, '')} LIMIT #{row_limit.to_i}")
              columns = result.columns
              rows = result.rows
              raise ActiveRecord::Rollback
            end
          end
          { columns: columns, rows: rows, row_count: rows.size, duration_ms: (duration * 1000).round }
        end
      end

      private

      def with_connection
        config = @data_source.connection_config_hash
        klass = ephemeral_connection_class
        klass.establish_connection(config)
        yield klass.connection
      ensure
        klass.remove_connection if defined?(klass) && klass.connected?
      end

      def ephemeral_connection_class
        class_name = "Nquery::DataSources::EphemeralConnection#{@data_source.id || "new"}#{object_id}"
        Class.new(ActiveRecord::Base) do
          self.abstract_class = true

          define_singleton_method(:name) { class_name }
        end
      end
    end
  end
end
