# frozen_string_literal: true

module Nquery
  class DashboardsController < ApplicationController
    include ChartResults
    include Browsable

    before_action :set_dashboard, only: %i[show edit update destroy archive unarchive update_layout]
    before_action :authorize_dashboard_view!, only: %i[show]
    before_action :authorize_dashboard_curate!, only: %i[edit update destroy archive unarchive update_layout]

    def index
      @dashboards = filter_viewable_dashboards(Dashboard.active.includes(:collection).order(:name))
    end

    def show
      @dashboard_cards = @dashboard.dashboard_cards
        .joins(:chart)
        .merge(Chart.active)
        .includes(:chart)
      @card_results = @dashboard_cards.index_with { |card| chart_result(card.chart) }
    end

    def edit
      @collections = assignable_collections
    end

    def update
      @collections = assignable_collections
      authorize_collection_access!(Collection.find(dashboard_params[:collection_id]), required: :curate) if dashboard_params[:collection_id].present?

      if @dashboard.update(dashboard_params)
        redirect_to dashboard_path(@dashboard), notice: "Dashboard updated."
      else
        render :edit, status: :unprocessable_content
      end
    end

    def destroy
      @dashboard.destroy
      redirect_to dashboards_path, notice: "Dashboard removed."
    end

    def archive
      @dashboard.archive!
      redirect_to dashboards_path, notice: "Dashboard archived."
    end

    def unarchive
      @dashboard.unarchive!
      redirect_to dashboard_path(@dashboard), notice: "Dashboard unarchived."
    end

    def update_layout
      card_layouts.each do |card_id, layout|
        card = @dashboard.dashboard_cards.find(card_id)
        card.update(pos_x: layout[:x], pos_y: layout[:y], width: layout[:w], height: layout[:h])
      end
      head :ok
    end

    private

    def set_dashboard
      @dashboard = if action_name.in?(%w[show edit])
                     Dashboard.includes(:creator, dashboard_cards: :chart).find(params[:id])
                   else
                     Dashboard.find(params[:id])
                   end
    end

    def authorize_dashboard_view!
      authorize_collection_access!(@dashboard.collection, required: :view)
    end

    def authorize_dashboard_curate!
      authorize_collection_access!(@dashboard.collection, required: :curate)
    end

    def card_layouts
      params.permit(cards: {}).fetch(:cards, {}).transform_values do |layout|
        layout.permit(:x, :y, :w, :h).to_h.symbolize_keys
      end
    end

    def dashboard_params
      params.require(:dashboard).permit(:name, :description, :collection_id, settings: {})
    end
  end
end
