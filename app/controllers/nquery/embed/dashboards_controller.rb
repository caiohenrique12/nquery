# frozen_string_literal: true

module Nquery
  module Embed
    class DashboardsController < ActionController::Base
      include Nquery::Engine.routes.url_helpers
      protect_from_forgery with: :exception
      layout "nquery/embed"

      def show
        payload = EmbedTokenService.verify(params[:token])
        @dashboard = Dashboard.includes(dashboard_cards: :chart).find(payload[:resource_id])
      rescue EmbedTokenService::Error
        render plain: "Invalid or expired embed token", status: :forbidden
      end
    end
  end
end
