# frozen_string_literal: true

module Nquery
  module SharingPage
    extend ActiveSupport::Concern

    private

    def assign_sharing_page(resource)
      @shareable = resource
      @embed_token = resource.active_embed_token
      @embed_url = signed_embed_url_for(resource)
      @public_url = public_share_url_for(resource)
    end

    def signed_embed_url_for(resource)
      token = resource.active_embed_token
      return unless token

      signed = EmbedTokenService.signed_token_for(token)
      if resource.is_a?(Dashboard)
        embed_public_dashboard_url(token: signed)
      else
        embed_public_chart_url(token: signed)
      end
    end

    def public_share_url_for(resource)
      return unless resource.publicly_shared?

      if resource.is_a?(Dashboard)
        public_dashboard_url(resource.public_uuid)
      else
        public_chart_url(resource.public_uuid)
      end
    end
  end
end
