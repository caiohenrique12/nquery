# frozen_string_literal: true

module Nquery
  module ChartsHelper
    def chart_dashboard
      @dashboard
    end

    def chart_show_path(chart, dashboard: chart_dashboard)
      dashboard ? dashboard_chart_path(dashboard, chart) : chart_path(chart)
    end

    def chart_edit_path(chart, dashboard: chart_dashboard)
      dashboard ? edit_dashboard_chart_path(dashboard, chart) : edit_chart_path(chart)
    end

    def chart_embed_path(chart, dashboard: chart_dashboard)
      dashboard ? embed_dashboard_chart_path(dashboard, chart) : embed_chart_path(chart)
    end

    def chart_archive_path(chart, dashboard: chart_dashboard)
      dashboard ? archive_dashboard_chart_path(dashboard, chart) : archive_chart_path(chart)
    end

    def chart_form_path(chart, dashboard: chart_dashboard)
      dashboard ? dashboard_chart_path(dashboard, chart) : chart_path(chart)
    end

    def chart_builder_chart_types
      Chart::CHART_TYPES - %w[table]
    end
  end
end
