# frozen_string_literal: true

module Nquery
  class ChartsController < ApplicationController
    include ChartActions

    before_action :set_root_collection, only: %i[new create]
    before_action :authorize_chart_create!, only: %i[new create]

    def new
      @chart = Chart.new
      @chart.build_query(statement: "SELECT 1 AS example")
      @data_sources = DataSource.active.order(:name)
      @schema_tables = schema_tables
    end

    def create
      @chart = Chart.new(
        chart_create_params.merge(
          creator: current_nquery_user,
          collection: @root_collection
        )
      )
      @chart.name = @chart.name.presence || @chart.query&.name
      @chart.visualization = { "type" => "bar" } if @chart.visualization.blank?
      @chart.query&.creator = current_nquery_user
      @chart.query&.collection = @root_collection

      if @chart.save
        redirect_to chart_path(@chart), notice: "Chart created."
      else
        @data_sources = DataSource.active.order(:name)
        @schema_tables = schema_tables
        render :new, status: :unprocessable_entity
      end
    end

    private

    def set_root_collection
      @root_collection = Collection.roots.first
      redirect_to root_path, alert: "No collection available." unless @root_collection
    end

    def authorize_chart_create!
      authorize_collection_access!(@root_collection, required: :curate)
    end

    def set_chart
      @chart = Chart.find(params[:id])
    end

    def chart_create_params
      params.require(:chart).permit(
        :name,
        visualization: {},
        query_attributes: %i[name statement data_source_id]
      )
    end

    def schema_tables
      data_source = DataSource.first
      return [] unless data_source

      DataSources::Adapter.for(data_source).tables
    rescue StandardError
      []
    end
  end
end
