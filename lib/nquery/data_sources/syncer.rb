# frozen_string_literal: true

module Nquery
  module DataSources
    class Syncer
      CREDENTIAL_KEYS = %i[host port database username password database_path sslmode].freeze

      def self.call
        new.call
      end

      def call
        Nquery.configuration.data_sources.each do |key, definition|
          sync_data_source!(key, definition)
        end
      end

      private

      def sync_data_source!(key, definition)
        attrs = normalize_definition(definition, key)
        data_source = DataSource.find_or_initialize_by(key: key.to_s)
        data_source.name = attrs.fetch(:name)
        data_source.adapter = attrs.fetch(:adapter).to_s
        data_source.connection_config_hash = {} if data_source.adapter == "rails"
        data_source.save!
        data_source
      end

      def normalize_definition(definition, key)
        if definition.is_a?(Hash)
          symbolized = definition.deep_symbolize_keys
          {
            adapter: symbolized.fetch(:adapter),
            name: symbolized.fetch(:name)
          }
        else
          {
            adapter: definition,
            name: default_name_for(key)
          }
        end
      end

      def default_name_for(key)
        key.to_s.humanize
      end
    end
  end
end
