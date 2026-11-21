# frozen_string_literal: true

module Nquery
  module Dashboards
    # Connects one dashboard filter to the charts whose queries use its variable.
    class ParameterCharts < ApplicationService
      def initialize(dashboard:, name:, chart_ids:)
        @dashboard = dashboard
        @name = name.to_s
        @chart_ids = Array(chart_ids).filter_map { |chart_id| Integer(chart_id, exception: false) }
      end

      def call
        parameters = @dashboard.parameter_definitions.map do |row|
          next row unless row["name"] == @name

          row.merge("chart_ids" => selected_chart_ids)
        end
        @dashboard.update!(parameters: parameters)
        @dashboard
      end

      private

      def selected_chart_ids
        allowed = @dashboard.charts.select { |chart| chart.uses_parameter?(@name) }.map(&:id)
        @chart_ids & allowed
      end
    end
  end
end
