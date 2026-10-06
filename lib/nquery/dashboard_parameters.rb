# frozen_string_literal: true

module Nquery
  # Merges declared dashboard defaults with embed token params and the query string.
  class DashboardParameters
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
        if parsed == :invalid
          invalid_names << definition["name"]
        elsif parsed != :omitted
          values[definition["name"]] = parsed
        end
      end

      Result.new(values: values, invalid_names: invalid_names)
    end

    private

    def resolve(definition)
      name = definition["name"]
      type = definition["type"]
      [@token_params, @request_params].each do |source|
        next unless source.key?(name)

        parsed = ParameterValue.parse(type, source[name])
        return parsed unless parsed == :omitted
      end

      ParameterValue.parse(type, definition["default"])
    end

    def stringify(source)
      return {} if source.blank?

      hash = source.respond_to?(:to_unsafe_h) ? source.to_unsafe_h : source.to_h
      hash.stringify_keys
    end
  end
end
