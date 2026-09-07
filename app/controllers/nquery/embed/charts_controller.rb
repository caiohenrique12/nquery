# frozen_string_literal: true

module Nquery
  module Embed
    class ChartsController < PublicResourcesController
      def show
        unless Nquery.configuration.static_embedding_enabled
          return render_forbidden("Embedding is disabled")
        end

        payload = EmbedTokenService.verify(params[:token])
        unless payload[:resource_type] == "Nquery::Chart"
          return render_forbidden
        end

        @chart = Chart.find(payload[:resource_id])
        unless @chart.enable_embedding?
          return render_forbidden("Embedding is disabled")
        end

        @result = shared_chart_result(@chart)
      rescue EmbedTokenService::Error, ActiveRecord::RecordNotFound
        render_forbidden
      end
    end
  end
end
