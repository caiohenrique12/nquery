# frozen_string_literal: true

module Nquery
  module Sharing
    class EmbedTokensController < BaseController
      def create
        unless Nquery.configuration.static_embedding_enabled
          return redirect_to sharing_page_path, alert: "Static embedding is disabled."
        end

        @shareable.embed_tokens.active.find_each { |token| EmbedTokenService.revoke!(token) }
        EmbedTokenService.sign(
          resource_type: @shareable.class.name,
          resource_id: @shareable.id,
          creator: current_nquery_user,
          expires_at: expires_at_from_param
        )
        @shareable.update!(enable_embedding: true) unless @shareable.enable_embedding?

        redirect_to sharing_page_path, notice: "Embed token generated."
      end

      def destroy
        token = @shareable.embed_tokens.find(params[:id])
        EmbedTokenService.revoke!(token)
        redirect_to sharing_page_path, notice: "Embed token revoked."
      end

      private

      def expires_at_from_param
        case params[:expires_in]
        when "1.day" then 1.day.from_now
        when "30.days" then 30.days.from_now
        when "never" then nil
        else 1.hour.from_now
        end
      end
    end
  end
end
