# frozen_string_literal: true

module Nquery
  module DataSources
    class Adapter
      def self.for(data_source)
        case data_source.adapter
        when "rails" then RailsAdapter.new(data_source)
        when "postgresql" then PostgresqlAdapter.new(data_source)
        when "mysql" then MysqlAdapter.new(data_source)
        when "sqlite" then SqliteAdapter.new(data_source)
        else
          raise ArgumentError, "Unknown adapter: #{data_source.adapter}"
        end
      end

      def initialize(data_source)
        @data_source = data_source
      end

      def tables
        raise NotImplementedError
      end

      def columns(table_name)
        raise NotImplementedError
      end

      def execute_readonly(statement, timeout: 15, row_limit: 10_000)
        raise NotImplementedError
      end
    end
  end
end
