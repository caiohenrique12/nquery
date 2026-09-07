# frozen_string_literal: true

module Nquery
  module ChartResults
    extend ActiveSupport::Concern

    SHARED_CHART_LOAD_ERROR = "This chart could not be loaded."

    private

    def chart_result(chart)
      return demo_result unless chart.statement?

      chart_query_result(chart)
    rescue StandardError
      demo_result
    end

    def chart_builder_result(chart)
      return nil unless chart.statement?

      chart_query_result(chart, audit: false)
    rescue QueryRunner::PermissionError, QueryRunner::Error => e
      { error: e.message }
    rescue StandardError => e
      { error: e.message }
    end

    def shared_chart_result(chart)
      return { error: "This chart has no query." } unless chart.statement?
      return { error: SHARED_CHART_LOAD_ERROR } unless chart.data_source

      chart_query_result(chart, audit: false)
    rescue StandardError => e
      Rails.logger.error("[nquery] shared chart #{chart.id} failed: #{e.class}: #{e.message}")
      { error: SHARED_CHART_LOAD_ERROR }
    end

    def chart_query_result(chart, audit: true)
      QueryRunner.new(
        data_source: chart.data_source || DataSource.first,
        statement: chart.statement,
        user: current_nquery_user,
        query: chart.query
      ).run(audit: audit)
    end

    def demo_result
      {
        columns: %w[month revenue],
        rows: [%w[Jan 1200], %w[Feb 1800], %w[Mar 2400], %w[Apr 2100]],
        row_count: 4
      }
    end
  end
end
