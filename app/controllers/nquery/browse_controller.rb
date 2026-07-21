# frozen_string_literal: true

module Nquery
  class BrowseController < ApplicationController
    def index
      @root_collection = Collection.roots.first || Collection.shared.first
      @collections = filter_viewable_collections(
        Collection.shared.includes(:children).where(parent_id: @root_collection&.id)
      )
      @charts = filter_viewable_charts(Chart.includes(:collection).order(:name))
      @dashboards = filter_viewable_dashboards(Dashboard.includes(:collection).order(:name))
    end

    private

    def filter_viewable_collections(relation)
      return relation if permission_resolver.admin?

      relation.select { |collection| viewable_collection?(collection) }
    end

    def filter_viewable_charts(relation)
      return relation if permission_resolver.admin?

      relation.select { |chart| viewable_collection?(chart.collection) }
    end

    def filter_viewable_dashboards(relation)
      return relation if permission_resolver.admin?

      relation.select { |dashboard| viewable_collection?(dashboard.collection) }
    end
  end
end
