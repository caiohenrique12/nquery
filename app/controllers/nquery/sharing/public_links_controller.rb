# frozen_string_literal: true

module Nquery
  module Sharing
    class PublicLinksController < BaseController
      def create
        unless Nquery.configuration.public_sharing_enabled
          return redirect_to sharing_page_path, alert: "Public sharing is disabled."
        end

        @shareable.share_publicly!(user: current_nquery_user)
        redirect_to sharing_page_path, notice: "Public link created."
      end

      def destroy
        @shareable.unshare_publicly!
        redirect_to sharing_page_path, notice: "Public link removed."
      end
    end
  end
end
