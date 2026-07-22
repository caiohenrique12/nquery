# frozen_string_literal: true

module Nquery
  class SchemaExplorer
    def self.tables_for(data_source)
      new(data_source).tables
    end

    def initialize(data_source)
      @data_source = data_source
    end

    def tables
      return [] unless @data_source

      adapter = DataSources::Adapter.for(@data_source)
      adapter.tables.map do |table|
        {
          name: table,
          columns: adapter.columns(table)
        }
      end
    rescue StandardError => e
      Rails.logger.error("[Nquery::SchemaExplorer] #{e.class}: #{e.message}\n#{e.backtrace&.first(8)&.join("\n")}")
      []
    end
  end
end
