# frozen_string_literal: true

module Nquery
  module Dashboards
    # Records which dashboard parameters apply to one chart.
    class CardParameters < ApplicationService
      def initialize(dashboard:, chart:, linked_names:)
        @dashboard = dashboard
        @chart = chart
        @linked_names = Array(linked_names).map(&:to_s)
      end

      def call
        @dashboard.update!(parameters: rewritten_parameters)
        @dashboard
      end

      private

      def rewritten_parameters
        @dashboard.parameter_definitions.map do |row|
          ids = current_chart_ids(row)
          ids = if @linked_names.include?(row["name"])
                  ids | [@chart.id]
                else
                  ids - [@chart.id]
                end
          row.merge("chart_ids" => ids)
        end
      end

      def current_chart_ids(row)
        @dashboard.linked_chart_ids(row)
      end
    end
  end
end
