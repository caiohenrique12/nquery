# frozen_string_literal: true

module Nquery
  class DashboardsController < ApplicationController
    before_action :set_dashboard, only: %i[show edit update update_layout]
    before_action :authorize_dashboard_collection!, only: %i[show edit update update_layout]

    def show
    end

    def edit
    end

    def update
      if @dashboard.update(dashboard_params)
        redirect_to dashboard_path(@dashboard), notice: "Dashboard updated."
      else
        render :edit, status: :unprocessable_entity
      end
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
                     Dashboard.includes(dashboard_cards: :chart).find(params[:id])
                   else
                     Dashboard.find(params[:id])
                   end
    end

    def authorize_dashboard_collection!
      authorize_collection_access!(@dashboard.collection, required: :view)
    end

    def card_layouts
      params.permit(cards: {}).fetch(:cards, {}).transform_values do |layout|
        layout.permit(:x, :y, :w, :h).to_h.symbolize_keys
      end
    end

    def dashboard_params
      params.require(:dashboard).permit(:name, :description, settings: {})
    end
  end
end
