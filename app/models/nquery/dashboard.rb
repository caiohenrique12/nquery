# frozen_string_literal: true

module Nquery
  class Dashboard < ApplicationRecord
    include Shareable

    belongs_to :collection, class_name: "Nquery::Collection"
    belongs_to :creator, class_name: "Nquery::User", optional: true
    has_many :dashboard_cards, class_name: "Nquery::DashboardCard", dependent: :destroy
    has_many :charts, through: :dashboard_cards, class_name: "Nquery::Chart"

    PARAMETER_NAME_FORMAT = /\A[a-z][a-z0-9_]*\z/
    RESERVED_PARAMETER_NAMES = %w[token titled bordered theme wire id action controller format].freeze

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

    def with_agreed_chart_variables
      loaded_charts = charts.includes(:query).to_a
      charts_by_id = loaded_charts.index_by(&:id)
      rows = parameter_definitions.map { |row| agreed_chart_variable_row(row, loaded_charts, charts_by_id) }
      return self if rows == parameter_definitions

      copy = dup
      copy.id = id
      copy.parameters = rows
      copy.readonly!
      copy
    end

    def parameter_linked_to_chart?(row, chart)
      return true unless row.key?("chart_ids")

      Array(row["chart_ids"]).map(&:to_i).include?(chart.id)
    end

    def linked_chart_ids(row)
      if row.key?("chart_ids")
        Array(row["chart_ids"]).map(&:to_i)
      else
        charts.select { |chart| chart.uses_parameter?(row["name"]) }.map(&:id)
      end
    end

    def parameters_for_chart(chart, resolved)
      names = parameter_definitions.select { |row| parameter_linked_to_chart?(row, chart) }.map { |row| row["name"] }
      DashboardParameters::Result.new(
        values: resolved.values.slice(*names),
        invalid_names: Array(resolved.invalid_names) & names
      )
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

      row = {
        "name" => name,
        "type" => attrs["type"].to_s.strip,
        "default" => attrs["default"].to_s.strip
      }
      row["chart_ids"] = chart_ids_for(attrs["chart_ids"]) if attrs.key?("chart_ids")
      row
    end

    def chart_ids_for(value)
      Array(value).filter_map { |chart_id| Integer(chart_id, exception: false) }.uniq
    end

    def agreed_chart_variable_row(row, loaded_charts, charts_by_id)
      definitions = linked_variable_definitions(row, loaded_charts, charts_by_id)
      return row if definitions.empty?

      types = definitions.map { |definition| definition["type"] }.uniq
      defaults = definitions.map { |definition| definition["default"] }.uniq
      return row unless types.one? && defaults.one?

      row.merge("type" => types.first, "default" => defaults.first)
    end

    def linked_variable_definitions(row, loaded_charts, charts_by_id)
      chart_ids_for_row(row, loaded_charts).filter_map do |chart_id|
        charts_by_id[chart_id]&.query&.stored_parameter_definitions&.find { |definition| definition["name"] == row["name"] }
      end
    end

    def chart_ids_for_row(row, loaded_charts)
      if row.key?("chart_ids")
        Array(row["chart_ids"]).map(&:to_i)
      else
        loaded_charts.select { |chart| chart.uses_parameter?(row["name"]) }.map(&:id)
      end
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
  end
end
