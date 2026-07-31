# frozen_string_literal: true

module Nquery
  class DataSource < ApplicationRecord
    ADAPTERS = %w[rails postgresql mysql sqlite].freeze
    REMOTE_ADAPTERS = %w[postgresql mysql].freeze
    SSL_MODES = %w[disable require verify-ca verify-full].freeze

    AR_ADAPTER_NAMES = {
      "postgresql" => "postgresql",
      "mysql" => "mysql2",
      "sqlite" => "sqlite3"
    }.freeze

    DEFAULT_PORTS = {
      "postgresql" => 5432,
      "mysql" => 3306
    }.freeze

    # serialize must be declared before encrypts for structured attributes.
    serialize :connection_config, coder: JSON
    encrypts :connection_config

    has_many :data_permissions, class_name: "Nquery::DataPermission", dependent: :destroy
    has_many :queries, class_name: "Nquery::Query", dependent: :nullify

    attr_accessor :host, :port, :database, :username, :password, :database_path, :sslmode, :connection_fields_submitted

    validates :name, presence: true
    validates :key, uniqueness: true, allow_nil: true
    validates :adapter, inclusion: { in: ADAPTERS }
    validate :validate_connection_fields, if: :connection_fields_submitted?

    before_validation :compose_connection_config

    scope :active, -> { all }

    def connection_fields_submitted?
      ActiveModel::Type::Boolean.new.cast(connection_fields_submitted)
    end

    def connection_config_hash
      value = connection_config
      return {} if value.blank?

      hash = value.is_a?(String) ? JSON.parse(value) : value
      normalize_config_hash(hash)
    rescue JSON::ParserError
      {}
    end

    def connection_config_hash=(hash)
      self.connection_config = hash.presence
    end

    def assign_connection_fields_from_config
      hash = connection_config_hash
      self.host = hash["host"]
      self.port = hash["port"]&.to_s
      self.database = hash["database"]
      self.username = hash["username"]
      self.database_path = hash["database_path"].presence || hash["database"]
      self.sslmode = hash["sslmode"]
      self.password = nil
    end

  private

    def compose_connection_config
      if adapter == "rails"
        self.connection_config = {}
        return
      end

      assign_connection_config_from_fields if connection_fields_submitted?
    end

    def validate_connection_fields
      case adapter
      when *REMOTE_ADAPTERS
        errors.add(:host, "can't be blank") if host.blank?
        errors.add(:database, "can't be blank") if database.blank?
        errors.add(:username, "can't be blank") if username.blank?
        errors.add(:password, "can't be blank") if password.blank? && (new_record? || existing_password.blank?)
        if sslmode.present? && !SSL_MODES.include?(sslmode)
          errors.add(:sslmode, "is not included in the list")
        end
      when "sqlite"
        errors.add(:database_path, "can't be blank") if database_path.blank?
      end
    end

    def assign_connection_config_from_fields
      previous = persisted? ? load_persisted_connection_config : {}

      self.connection_config = case adapter
      when "sqlite"
        {
          "adapter" => AR_ADAPTER_NAMES.fetch(adapter),
          "database" => database_path.to_s
        }
      when *REMOTE_ADAPTERS
        config = {
          "adapter" => AR_ADAPTER_NAMES.fetch(adapter),
          "host" => host.to_s,
          "port" => resolved_port,
          "database" => database.to_s,
          "username" => username.to_s
        }
        config["password"] = resolved_password(previous)
        config["sslmode"] = sslmode if sslmode.present?
        config
      else
        {}
      end
    end

    def resolved_port
      port.presence&.to_i || DEFAULT_PORTS.fetch(adapter)
    end

    def resolved_password(previous)
      return password if password.present?

      previous["password"]
    end

    def existing_password
      connection_config_hash["password"]
    end

    def load_persisted_connection_config
      normalize_config_hash(self.class.find(id).connection_config.presence || {})
    end

    def normalize_config_hash(hash)
      hash.stringify_keys
    end
  end
end
