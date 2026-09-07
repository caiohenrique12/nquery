# frozen_string_literal: true

module Nquery
  module Sharing
    class BaseController < ApplicationController
      before_action :set_shareable
      before_action :authorize_shareable_publish!, only: %i[create update]
      before_action :authorize_shareable_revoke!, only: %i[destroy]

      private

      def set_shareable
        @shareable = if params[:chart_id]
                       Chart.find(params[:chart_id])
                     else
                       Dashboard.find(params[:dashboard_id])
                     end
      end

      def authorize_shareable_publish!
        authorize_shareable_collection!
        return if performed?

        if shareable_missing_data_source?
          deny_collection_access!(missing_data_source_message)
          return
        end

        shareable_data_sources.each do |data_source|
          authorize_data_source_access!(data_source)
          return if performed?
        end
      end

      def authorize_shareable_revoke!
        authorize_shareable_collection!
      end

      def authorize_shareable_collection!
        return if permission_resolver.admin?

        if @shareable.collection.nil?
          deny_collection_access!("You do not have permission to access this collection.")
          return
        end

        authorize_collection_access!(@shareable.collection, required: :curate)
      end

      def shareable_charts
        if @shareable.is_a?(Chart)
          [@shareable]
        else
          @shareable.dashboard_cards
            .joins(:chart)
            .merge(Chart.active)
            .includes(chart: { query: :data_source })
            .map(&:chart)
        end
      end

      def shareable_data_sources
        shareable_charts.filter_map { |chart| chart.query&.data_source }.uniq
      end

      def shareable_missing_data_source?
        shareable_charts.any? { |chart| chart.query && chart.query.data_source.nil? }
      end

      def missing_data_source_message
        if @shareable.is_a?(Chart)
          "This chart has no data source."
        else
          "A chart on this dashboard has no data source."
        end
      end

      def sharing_page_path
        if params[:chart_id] && params[:dashboard_id]
          embed_dashboard_chart_path(params[:dashboard_id], params[:chart_id])
        elsif params[:chart_id]
          embed_chart_path(params[:chart_id])
        else
          embed_dashboard_path(params[:dashboard_id])
        end
      end
    end
  end
end
