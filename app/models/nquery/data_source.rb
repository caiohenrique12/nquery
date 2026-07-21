# frozen_string_literal: true

module Nquery
  class DataSource < ApplicationRecord
    ADAPTERS = %w[rails postgresql mysql sqlite].freeze

    has_many :data_permissions, class_name: "Nquery::DataPermission", dependent: :destroy
    has_many :queries, class_name: "Nquery::Query", dependent: :nullify

    validates :name, presence: true
    validates :adapter, inclusion: { in: ADAPTERS }

    scope :active, -> { all }

    def connection_config_hash
      return {} if connection_config.blank?

      JSON.parse(connection_config)
    rescue JSON::ParserError
      {}
    end

    def connection_config_hash=(hash)
      self.connection_config = hash.to_json
    end
  end
end
