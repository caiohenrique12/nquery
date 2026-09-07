# frozen_string_literal: true

module Nquery
  module Embed
    class DashboardsController < PublicResourcesController
      def show
        unless Nquery.configuration.static_embedding_enabled
          return render_forbidden("Embedding is disabled")
        end

        payload = EmbedTokenService.verify(params[:token])
        unless payload[:resource_type] == "Nquery::Dashboard"
          return render_forbidden
        end

        @dashboard = Dashboard.find(payload[:resource_id])
        unless @dashboard.enable_embedding?
          return render_forbidden("Embedding is disabled")
        end

        @dashboard_cards = load_dashboard_cards(@dashboard)
        @card_results = @dashboard_cards.index_with { |card| shared_chart_result(card.chart) }
      rescue EmbedTokenService::Error, ActiveRecord::RecordNotFound
        render_forbidden
      end
    end
  end
end
