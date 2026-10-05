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

        @dashboard = Dashboard.active.find(payload[:resource_id])
        unless @dashboard.enable_embedding?
          return render_forbidden("Embedding is disabled")
        end

        resolved = DashboardParameters.call(
          dashboard: @dashboard,
          token_params: embed_parameter_params(payload[:params]),
          request_params: embed_parameter_params(params)
        )
        @dashboard_cards = load_dashboard_cards(@dashboard)
        @card_results = @dashboard_cards.index_with do |card|
          shared_chart_result(card.chart, parameters: resolved)
        end
      rescue EmbedTokenService::Error, ActiveRecord::RecordNotFound
        render_forbidden
      end

      private

      def embed_parameter_params(source)
        return {} if source.blank?

        hash = source.respond_to?(:to_unsafe_h) ? source.to_unsafe_h : source.to_h
        hash.stringify_keys.except("token", "titled", "bordered", "theme").slice(*@dashboard.parameter_names)
      end
    end
  end
end
