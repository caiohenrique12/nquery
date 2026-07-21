# frozen_string_literal: true

module Nquery
  module ChartActions
    extend ActiveSupport::Concern

    included do
      include ChartResults
      before_action :set_chart, only: %i[show edit update embed destroy archive]
      before_action :authorize_chart_view!, only: %i[show embed]
      before_action :authorize_chart_curate!, only: %i[edit update destroy archive]
    end

    def show
      @result = chart_result(@chart)
      render "nquery/charts/show"
    end

    def edit
      @chart_types = Chart::CHART_TYPES
      render "nquery/charts/edit"
    end

    def update
      if @chart.update(chart_params)
        redirect_to after_chart_update_path, notice: "Chart updated."
      else
        @chart_types = Chart::CHART_TYPES
        render "nquery/charts/edit", status: :unprocessable_entity
      end
    end

    def destroy
      @chart.destroy
      redirect_to after_chart_action_path, notice: "Chart removed."
    end

    def archive
      @chart.archive!
      redirect_to after_chart_action_path, notice: "Chart archived."
    end

    def embed
      @embed_token = EmbedToken.active.find_by(resource_type: "Nquery::Chart", resource_id: @chart.id)
      @embed_url = @embed_token ? embed_public_chart_url(token: EmbedTokenService.signed_token_for(@embed_token)) : nil
      render "nquery/charts/embed"
    end

    private

    def authorize_chart_view!
      authorize_collection_access!(@chart.collection, required: :view)
    end

    def authorize_chart_curate!
      authorize_collection_access!(@chart.collection, required: :curate)
    end

    def after_chart_update_path
      if chart_dashboard
        dashboard_chart_path(chart_dashboard, @chart)
      else
        chart_path(@chart)
      end
    end

    def after_chart_action_path
      if chart_dashboard
        dashboard_path(chart_dashboard)
      elsif @chart.collection
        collection_path(@chart.collection)
      else
        root_path
      end
    end

    def chart_dashboard
      @dashboard if defined?(@dashboard) && @dashboard.present?
    end

    def chart_params
      params.require(:chart).permit(:name, visualization: {})
    end
  end
end
