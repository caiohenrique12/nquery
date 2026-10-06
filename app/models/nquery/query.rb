# frozen_string_literal: true

module Nquery
  class Query < ApplicationRecord
    belongs_to :data_source, class_name: "Nquery::DataSource", optional: true
    belongs_to :creator, class_name: "Nquery::User", optional: true
    belongs_to :collection, class_name: "Nquery::Collection", optional: true
    has_one :chart, class_name: "Nquery::Chart", dependent: :destroy
    has_many :audits, class_name: "Nquery::Audit", dependent: :nullify

    PARAMETER_NAME_FORMAT = /\A[a-z][a-z0-9_]*\z/
    RESERVED_PARAMETER_NAMES = %w[token titled bordered theme wire id action controller format].freeze

    validates :name, presence: true, on: :update
    validate :statement_must_be_readonly
    validate :parameters_are_declared

    before_validation :set_default_name, on: :create
    before_validation :normalize_parameters

    def set_default_name
      self.name ||= "Untitled query"
    end

    def statement?
      statement.present?
    end

    def statement_parameter_names
      statement.to_s.scan(StatementBinds::PLACEHOLDER).flatten.uniq
    end

    def stored_parameter_definitions
      stored = normalized_parameter_rows(parameters).index_by { |row| row["name"] }
      statement_parameter_names.filter_map { |name| stored[name] }
    end

    def parameter_definitions
      stored = stored_parameter_definitions.index_by { |row| row["name"] }
      statement_parameter_names.map do |name|
        stored[name] || { "name" => name, "type" => "string", "default" => "" }
      end
    end

    private

    def normalize_parameters
      self.parameters = stored_parameter_definitions
    end

    def normalized_parameter_rows(value)
      Array(value).filter_map { |row| normalized_parameter_row(row) }
    end

    def normalized_parameter_row(row)
      return unless row.respond_to?(:stringify_keys)

      attrs = row.stringify_keys
      name = attrs["name"].to_s.strip
      return if name.blank?

      {
        "name" => name,
        "type" => attrs["type"].to_s.strip,
        "default" => attrs["default"].to_s.strip
      }
    end

    def parameters_are_declared
      names = []
      parameter_definitions.each do |row|
        name = row["name"]
        unless name.match?(PARAMETER_NAME_FORMAT)
          errors.add(:parameters, "include an invalid name")
          next
        end

        errors.add(:parameters, "cannot use #{name}") if RESERVED_PARAMETER_NAMES.include?(name)

        if names.include?(name)
          errors.add(:parameters, "include a duplicate name")
        else
          names << name
        end

        if ParameterValue::TYPES.exclude?(row["type"])
          errors.add(:parameters, "must be string, integer, date, datetime, uuid, or boolean")
        elsif !ParameterValue.valid_default?(row["type"], row["default"])
          errors.add(:parameters, "include an invalid default")
        end
      end
    end

    def statement_must_be_readonly
      message = ReadonlySql.error_message(statement, allow_blank: true)
      errors.add(:statement, message) if message
    end
  end
end
