# frozen_string_literal: true

module Nquery
  module Embed
    class ChartsController < ActionController::Base
      include Nquery::Engine.routes.url_helpers
      protect_from_forgery with: :exception
      layout "nquery/embed"

      def show
        payload = EmbedTokenService.verify(params[:token])
        @chart = Chart.find(payload[:resource_id])
        @result = demo_result
      rescue EmbedTokenService::Error
        render plain: "Invalid or expired embed token", status: :forbidden
      end

      private

      def demo_result
        { columns: %w[month revenue], rows: [%w[Jan 1200], %w[Feb 1800], %w[Mar 2400]] }
      end
    end
  end
end
