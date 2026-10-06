# frozen_string_literal: true

module Nquery
  class Dashboard::CardsController < ApplicationController
    before_action :set_dashboard
    before_action :authorize_dashboard_curate!

    def parameters
      card = @dashboard.dashboard_cards.find(params[:id])
      Dashboards::CardParameters.call(
        dashboard: @dashboard,
        chart: card.chart,
        linked_names: Array(params[:parameter_names])
      )
      redirect_to dashboard_path(@dashboard), notice: "Chart filters updated."
    end

    private

    def set_dashboard
      @dashboard = Dashboard.find(params[:dashboard_id])
    end

    def authorize_dashboard_curate!
      authorize_collection_access!(@dashboard.collection, required: :curate)
    end
  end
end
