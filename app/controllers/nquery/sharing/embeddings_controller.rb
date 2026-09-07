# frozen_string_literal: true

module Nquery
  module Sharing
    class EmbeddingsController < BaseController
      def update
        unless Nquery.configuration.static_embedding_enabled
          return redirect_to sharing_page_path, alert: "Static embedding is disabled."
        end

        enabled = ActiveModel::Type::Boolean.new.cast(params[:enable_embedding])
        @shareable.update!(enable_embedding: enabled)
        redirect_to sharing_page_path, notice: enabled ? "Embedding enabled." : "Embedding disabled."
      end
    end
  end
end
