# frozen_string_literal: true

module Nquery
  module ChartResults
    extend ActiveSupport::Concern

    private

    def chart_result(chart)
      return demo_result unless chart.query&.statement.present?

      QueryRunner.new(
        data_source: chart.query.data_source || DataSource.first,
        statement: chart.query.statement,
        user: current_nquery_user,
        query: chart.query
      ).run
    rescue StandardError
      demo_result
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
