# frozen_string_literal: true

module Nquery
  module Dashboards
    # Fills blank submitted parameter rows from charts whose queries declare the name.
    class ParameterRows < ApplicationService
      def initialize(dashboard:, attributes:)
        @dashboard = dashboard
        @attributes = attributes
      end

      def call
        fill_blank_rows
        @attributes
      end

      private

      def fill_blank_rows
        return unless @dashboard

        Array(@attributes[:parameters]).each { |row| fill_row(row) }
      end

      def fill_row(row)
        return if row[:type].present?

        source = chart_parameter(row[:name])
        return unless source

        row[:type] = source["type"]
        row[:default] = source["default"] if row[:default].blank?
        return if submitted_chart_ids?(row)

        ids = charts_for(row[:name]).map(&:id)
        row[:chart_ids] = ids if ids.any?
      end

      def submitted_chart_ids?(row)
        Array(row[:chart_ids]).any?(&:present?)
      end

      def chart_parameter(name)
        charts_for(name).filter_map { |chart| definition_named(chart, name) }.first
      end

      def charts_for(name)
        dashboard_charts.select { |chart| definition_named(chart, name) }
      end

      def dashboard_charts
        @dashboard_charts ||= @dashboard.charts.includes(:query).to_a
      end

      def definition_named(chart, name)
        chart.query&.parameter_definitions&.find { |definition| definition["name"] == name }
      end
    end
  end
end
