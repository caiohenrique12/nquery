# frozen_string_literal: true

module Nquery
  class HomeController < ApplicationController
    def index
      @recent_charts = Chart.includes(:collection, :creator).order(updated_at: :desc).limit(6)
      @recent_dashboards = Dashboard.includes(:collection, :creator).order(updated_at: :desc).limit(6)
      @recent_activity = Audit.includes(:user, :query).recent.limit(10)
    end
  end
end
