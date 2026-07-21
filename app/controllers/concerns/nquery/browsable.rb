# frozen_string_literal: true

module Nquery
  module Browsable
    extend ActiveSupport::Concern

    private

    def load_collection_contents(collection)
      @child_collections = filter_viewable_collections(collection.children.active.order(:name))
      @charts = filter_viewable_charts(collection.charts.active.includes(:collection).order(:name))
      @dashboards = filter_viewable_dashboards(
        collection.dashboards.active.includes(:creator, dashboard_cards: :chart).order(:name)
      )
      assigned_chart_ids = @dashboards.flat_map { |dashboard| dashboard.dashboard_cards.map(&:chart_id) }
      @standalone_charts = @charts.reject { |chart| assigned_chart_ids.include?(chart.id) }
    end

    def viewable_collections
      scope = Collection.active.includes(:parent).order(:name)
      return scope if permission_resolver.admin?

      scope.select { |collection| collection_listable?(collection) }
    end

    def assignable_collections
      Collection.shared.active.order(:name).select do |collection|
        permission_resolver.admin? || permission_resolver.collection_access(collection) == :curate
      end
    end

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

    def collection_listable?(collection)
      return false if collection.kind == "personal" && collection.owner_id != current_nquery_user&.id

      viewable_collection?(collection)
    end
  end
end
