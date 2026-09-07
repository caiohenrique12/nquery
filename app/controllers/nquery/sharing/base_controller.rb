# frozen_string_literal: true

module Nquery
  module Sharing
    class BaseController < ApplicationController
      before_action :set_shareable
      before_action :authorize_shareable_curate!

      private

      def set_shareable
        @shareable = if params[:chart_id]
                       Chart.find(params[:chart_id])
                     else
                       Dashboard.find(params[:dashboard_id])
                     end
      end

      def authorize_shareable_curate!
        authorize_collection_access!(@shareable.collection, required: :curate)
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
