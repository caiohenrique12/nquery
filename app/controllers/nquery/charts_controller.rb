# frozen_string_literal: true

module Nquery
  class ChartsController < ApplicationController
    before_action :set_chart, only: %i[show edit update embed]
    before_action :authorize_chart_collection!, only: %i[show edit update embed]

    def show
      @result = chart_result(@chart)
    end

    def edit
      @chart_types = Chart::CHART_TYPES
    end

    def update
      if @chart.update(chart_params)
        redirect_to chart_path(@chart), notice: "Chart updated."
      else
        @chart_types = Chart::CHART_TYPES
        render :edit, status: :unprocessable_entity
      end
    end

    def embed
      @embed_token = EmbedToken.active.find_by(resource_type: "Nquery::Chart", resource_id: @chart.id)
      @embed_url = @embed_token ? embed_public_chart_url(token: EmbedTokenService.signed_token_for(@embed_token)) : nil
    end

    private

    def set_chart
      @chart = Chart.find(params[:id])
    end

    def authorize_chart_collection!
      authorize_collection_access!(@chart.collection, required: :view)
    end

    def chart_params
      params.require(:chart).permit(:name, visualization: {})
    end

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
