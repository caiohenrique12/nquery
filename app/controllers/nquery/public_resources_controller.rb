# frozen_string_literal: true

module Nquery
  class PublicResourcesController < ActionController::Base
    include Nquery::Engine.routes.url_helpers
    include ChartResults

    protect_from_forgery with: :exception
    layout "nquery/embed"

    helper Nquery::Engine.helpers
    helper_method :current_nquery_user, :embed_titled?, :embed_bordered?, :embed_theme, :embed_appearance_classes

    after_action :set_embed_headers

    rate_limit to: 60, within: 1.minute if respond_to?(:rate_limit)

    private

    def current_nquery_user
      nil
    end

    def embed_titled?
      params[:titled] != "false"
    end

    def embed_bordered?
      params[:bordered] != "false"
    end

    def embed_theme
      theme = params[:theme].to_s
      theme.presence_in(%w[night transparent])
    end

    def embed_appearance_classes
      classes = ["nq-embed-body"]
      classes << "nq-embed-untitled" unless embed_titled?
      classes << "nq-embed-borderless" unless embed_bordered?
      classes << "nq-embed-theme-#{embed_theme}" if embed_theme
      classes
    end

    def set_embed_headers
      response.headers.delete("X-Frame-Options")
      response.headers["Content-Security-Policy"] = "frame-ancestors #{frame_ancestors_value}"
      response.headers["X-Robots-Tag"] = "noindex"
    end

    def frame_ancestors_value
      ancestors = Nquery.configuration.embed_frame_ancestors
      ancestors.present? ? Array(ancestors).join(" ") : "*"
    end

    def render_unavailable(status:, message: "This visualization is not available.")
      @unavailable_message = message
      render template: "nquery/embed/unavailable", status: status
    end

    def render_forbidden(message = "Invalid or expired embed token")
      render_unavailable(status: :forbidden, message: message)
    end

    def load_dashboard_cards(dashboard)
      dashboard.dashboard_cards
        .joins(:chart)
        .merge(Chart.active)
        .includes(chart: :query)
    end
  end
end
