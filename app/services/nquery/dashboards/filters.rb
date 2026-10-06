# frozen_string_literal: true

module Nquery
  module Dashboards
    class Filters < ApplicationService
      Result = Data.define(:filter_dashboard, :parameters)

      def initialize(dashboard:, request_params:)
        @dashboard = dashboard
        @request_params = request_params
      end

      def call
        source = filter_dashboard.with_agreed_chart_variables
        Result.new(
          filter_dashboard: source,
          parameters: DashboardParameters.call(
            dashboard: without_cleared_defaults(source),
            token_params: {},
            request_params: filter_values(source)
          )
        )
      end

      private

      def filter_dashboard
        return @dashboard unless @dashboard.errors.any?

        Dashboard.find(@dashboard.id)
      end

      def without_cleared_defaults(source)
        cleared = cleared_names(source)
        return source if cleared.empty?

        rows = source.parameter_definitions.map do |row|
          cleared.include?(row["name"]) ? row.merge("default" => "") : row
        end
        copy = source.dup
        copy.id = source.id
        copy.parameters = rows
        copy.readonly!
        copy
      end

      def cleared_names(source)
        submitted = permitted_params(source)
        source.parameter_names.select { |name| submitted.key?(name) && submitted[name].to_s.strip.blank? }
      end

      def filter_values(source)
        submitted = permitted_params(source)
        source.parameter_definitions.each_with_object({}) do |row, values|
          name = row["name"]
          next if submitted.key?(name) && submitted[name].to_s.strip.blank?

          text = submitted.key?(name) ? submitted[name].to_s.strip : row["default"].to_s.strip
          values[name] = text if text.present?
        end
      end

      def permitted_params(source)
        return {} if source.parameter_names.empty?

        raw = if @request_params.respond_to?(:permit)
                @request_params.permit(*source.parameter_names)
              else
                @request_params.to_h
              end
        raw.stringify_keys
      end
    end
  end
end
