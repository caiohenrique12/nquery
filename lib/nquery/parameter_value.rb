# frozen_string_literal: true

module Nquery
  # Turns a dashboard parameter string into a value that can be bound into SQL.
  class ParameterValue
    TYPES = %w[string integer date datetime uuid boolean].freeze
    TYPE_LABELS = {
      "string" => "String",
      "integer" => "Integer",
      "date" => "Date",
      "datetime" => "Datetime",
      "uuid" => "UUID",
      "boolean" => "Boolean"
    }.freeze
    TRUE_VALUES = %w[true 1 yes].freeze
    FALSE_VALUES = %w[false 0 no].freeze
    ISO_DATE = /\A\d{4}-\d{2}-\d{2}\z/
    INTEGER = /\A-?\d+\z/
    DATETIME = /\A\d{4}-\d{2}-\d{2}[T ]\d{2}:\d{2}(:\d{2})?(Z|[+-]\d{2}:?\d{2})?\z/
    UUID = /\A[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}\z/i

    def self.type_options
      TYPE_LABELS.map { |value, label| [label, value] }
    end

    def self.valid_default?(type, value)
      parse(type, value) != :invalid
    end

    def self.boolean_form_value(value)
      case parse("boolean", value)
      when true then "true"
      when false then "false"
      end
    end

    def self.parse(type, value)
      text = value.to_s.strip
      return :omitted if text.blank?

      case type.to_s
      when "string" then text
      when "integer" then parse_integer(text)
      when "date" then parse_date(text)
      when "datetime" then parse_datetime(text)
      when "uuid" then parse_uuid(text)
      when "boolean" then parse_boolean(text)
      else :invalid
      end
    end

    def self.parse_integer(text)
      return :invalid unless text.match?(INTEGER)

      Integer(text, 10)
    end

    def self.parse_date(text)
      return :invalid unless text.match?(ISO_DATE)

      Date.iso8601(text)
    rescue ArgumentError
      :invalid
    end

    def self.parse_datetime(text)
      return :invalid unless text.match?(DATETIME)

      date_text, time_text = text.split(/[T ]/, 2)
      Date.iso8601(date_text)
      normalized = "#{date_text}T#{time_text}"
      if normalized.match?(/Z\z|[+-]\d{2}:?\d{2}\z/)
        Time.iso8601(normalized)
      else
        Time.zone.parse(normalized) || :invalid
      end
    rescue ArgumentError, TypeError
      :invalid
    end

    def self.parse_uuid(text)
      return :invalid unless text.match?(UUID)

      text.downcase
    end

    def self.parse_boolean(text)
      normalized = text.downcase
      return true if TRUE_VALUES.include?(normalized)
      return false if FALSE_VALUES.include?(normalized)

      :invalid
    end

    private_class_method :parse_integer, :parse_date, :parse_datetime, :parse_uuid, :parse_boolean
  end
end
