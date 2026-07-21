# frozen_string_literal: true

module Nquery
  module Admin
    class PermissionsController < BaseController
      def index
        redirect_to by_group_admin_permissions_path
      end

      def by_group
        @view = "group"
        @groups = Group.order(:name)
        @selected_group = Group.find_by(id: params[:group_id]) || @groups.first
        @collections = Collection.shared.order(:name)
        @data_sources = DataSource.order(:name)
        @warnings = permission_warnings(@selected_group)
      end

      def by_data_source
        @view = "data_source"
        @data_sources = DataSource.order(:name)
        @selected_data_source = DataSource.find_by(id: params[:data_source_id]) || @data_sources.first
        @groups = Group.order(:name)
      end

      def by_collection
        @view = "collection"
        @collections = Collection.shared.order(:name)
        @selected_collection = Collection.find_by(id: params[:collection_id]) || @collections.first
        @groups = Group.order(:name)
        @warnings = @groups.filter_map do |group|
          "All Users is more permissive than #{group.name}" if permission_resolver.all_users_more_permissive?(group, collection: @selected_collection)
        end
      end

      private

      def permission_warnings(group)
        return [] unless group

        Collection.shared.filter_map do |collection|
          next unless permission_resolver.all_users_more_permissive?(group, collection: collection)

          "All Users has broader access than #{group.name} on #{collection.name}"
        end
      end

      def permission_resolver
        @permission_resolver ||= Permissions::Resolver.new(current_nquery_user)
      end
    end
  end
end
