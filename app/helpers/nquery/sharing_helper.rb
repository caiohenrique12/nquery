# frozen_string_literal: true

module Nquery
  module SharingHelper
    EMBED_EXPIRY_OPTIONS = [
      ["1 hour", "1.hour"],
      ["1 day", "1.day"],
      ["30 days", "30.days"],
      ["Never", "never"]
    ].freeze

    def shareable_public_link_path(resource)
      case resource
      when Chart
        chart_dashboard ? dashboard_chart_public_link_path(chart_dashboard, resource) : chart_public_link_path(resource)
      when Dashboard
        dashboard_public_link_path(resource)
      end
    end

    def shareable_embedding_path(resource)
      case resource
      when Chart
        chart_dashboard ? dashboard_chart_embedding_path(chart_dashboard, resource) : chart_embedding_path(resource)
      when Dashboard
        dashboard_embedding_path(resource)
      end
    end

    def shareable_embed_tokens_path(resource)
      case resource
      when Chart
        chart_dashboard ? dashboard_chart_embed_tokens_path(chart_dashboard, resource) : chart_embed_tokens_path(resource)
      when Dashboard
        dashboard_embed_tokens_path(resource)
      end
    end

    def shareable_embed_token_path(resource, token)
      case resource
      when Chart
        if chart_dashboard
          dashboard_chart_embed_token_path(chart_dashboard, resource, token)
        else
          chart_embed_token_path(resource, token)
        end
      when Dashboard
        dashboard_embed_token_path(resource, token)
      end
    end

    def can_curate_shareable?(resource)
      return true if permission_resolver.admin?
      return false if resource.collection.nil?

      permission_resolver.collection_access(resource.collection) == :curate
    end

    def share_iframe_snippet(url, height: 600)
      %(<iframe src="#{url}" width="800" height="#{height}" frameborder="0" loading="lazy"></iframe>)
    end

    def share_iframe_height(resource)
      resource.is_a?(Dashboard) ? 800 : 600
    end
  end
end
