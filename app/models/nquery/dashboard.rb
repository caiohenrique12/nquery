# frozen_string_literal: true

module Nquery
  class Dashboard < ApplicationRecord
    include Shareable

    belongs_to :collection, class_name: "Nquery::Collection"
    belongs_to :creator, class_name: "Nquery::User", optional: true
    has_many :dashboard_cards, class_name: "Nquery::DashboardCard", dependent: :destroy
    has_many :charts, through: :dashboard_cards, class_name: "Nquery::Chart"

    PARAMETER_NAME_FORMAT = /\A[a-z][a-z0-9_]*\z/
    RESERVED_PARAMETER_NAMES = %w[token titled bordered theme].freeze
    ISO_DATE = /\A\d{4}-\d{2}-\d{2}\z/

    scope :active, -> { where(archived_at: nil) }
    scope :archived, -> { where.not(archived_at: nil) }

    validates :name, presence: true
    validate :parameters_are_declared

    before_validation :normalize_parameters

    def parameter_definitions
      normalized_parameter_rows(parameters)
    end

    def parameter_names
      parameter_definitions.map { |row| row["name"] }
    end

    def archived?
      archived_at.present?
    end

    def archive!
      update!(archived_at: Time.current)
    end

    def unarchive!
      update!(archived_at: nil)
    end

    private

    def normalize_parameters
      self.parameters = parameter_definitions
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

        errors.add(:parameters, "must use the date type") unless row["type"] == "date"
        errors.add(:parameters, "include an invalid default") unless blank_or_iso_date?(row["default"])
      end
    end

    def blank_or_iso_date?(value)
      text = value.to_s
      return true if text.blank?
      return false unless text.match?(ISO_DATE)

      Date.iso8601(text)
      true
    rescue ArgumentError
      false
    end
  end
end
