# frozen_string_literal: true

module Nquery
  # Merges declared dashboard defaults with embed token params and the query string.
  class DashboardParameters
    ISO_DATE = /\A\d{4}-\d{2}-\d{2}\z/
    Result = Data.define(:values, :invalid_names)

    def self.call(dashboard:, token_params:, request_params:)
      new(dashboard:, token_params:, request_params:).call
    end

    def initialize(dashboard:, token_params:, request_params:)
      @dashboard = dashboard
      @token_params = stringify(token_params)
      @request_params = stringify(request_params)
    end

    def call
      values = {}
      invalid_names = []

      @dashboard.parameter_definitions.each do |definition|
        parsed = resolve(definition)
        if parsed.instance_of?(Date)
          values[definition["name"]] = parsed
        elsif parsed == :invalid
          invalid_names << definition["name"]
        end
      end

      Result.new(values: values, invalid_names: invalid_names)
    end

    private

    def resolve(definition)
      name = definition["name"]
      [@request_params, @token_params].each do |source|
        next unless source.key?(name)

        parsed = parse_date(source[name])
        return parsed unless parsed == :omitted
      end

      parse_date(definition["default"])
    end

    def parse_date(value)
      text = value.to_s.strip
      return :omitted if text.blank?
      return :invalid unless text.match?(ISO_DATE)

      Date.iso8601(text)
    rescue ArgumentError
      :invalid
    end

    def stringify(source)
      return {} if source.blank?

      hash = source.respond_to?(:to_unsafe_h) ? source.to_unsafe_h : source.to_h
      hash.stringify_keys
    end
  end
end
