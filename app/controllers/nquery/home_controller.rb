# frozen_string_literal: true

module Nquery
  class HomeController < ApplicationController
    include Browsable

    def index
      charts = Chart.active.includes(:collection, :creator).order(updated_at: :desc).limit(12)
      dashboards = Dashboard.active.includes(:collection, :creator, :dashboard_cards).order(updated_at: :desc).limit(12)

      @recent_charts = filter_viewable_charts(charts).first(6)
      @recent_dashboards = filter_viewable_dashboards(dashboards).first(6)
      @root_collection = Collection.roots.first
    end
  end
end
