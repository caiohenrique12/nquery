# frozen_string_literal: true

module Nquery
  class Dashboard::ChartsController < ApplicationController
    include ChartActions

    prepend_before_action :set_dashboard
    before_action :authorize_dashboard_view!, only: %i[show embed]
    before_action :authorize_dashboard_curate!, except: %i[show embed]

    def new
      @chart = Chart.new
      @chart.build_query(statement: "SELECT 1 AS example")
      load_chart_builder_assigns
    end

    def create
      @chart = Chart.new(
        chart_params.merge(
          creator: current_nquery_user,
          collection: @dashboard.collection
        )
      )
      @chart.name = @chart.name.presence || @chart.query&.name
      @chart.visualization = { "type" => "table" } if @chart.visualization.blank?
      @chart.query&.creator = current_nquery_user
      @chart.query&.collection = @dashboard.collection

      if @chart.save
        @dashboard.dashboard_cards.create!(
          chart: @chart,
          pos_x: 0,
          pos_y: 0,
          width: 6,
          height: 4
        )
        redirect_to edit_dashboard_chart_path(@dashboard, @chart), notice: "Chart created."
      else
        load_chart_builder_assigns
        render :new, status: :unprocessable_entity
      end
    end

    private

    def set_dashboard
      @dashboard = Dashboard.find(params[:dashboard_id])
    end

    def set_chart
      @chart = @dashboard.charts.find(params[:id])
    end

    def authorize_dashboard_view!
      authorize_collection_access!(@dashboard.collection, required: :view)
    end

    def authorize_dashboard_curate!
      authorize_collection_access!(@dashboard.collection, required: :curate)
    end
  end
end
