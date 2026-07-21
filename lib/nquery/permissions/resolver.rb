# frozen_string_literal: true

module Nquery
  module Permissions
    class Resolver
      COLLECTION_LEVELS = { "no_access" => 0, "view" => 1, "curate" => 2 }.freeze
      DATA_VIEW_LEVELS = { "blocked" => 0, "can_view" => 1 }.freeze
      CREATE_QUERY_LEVELS = { "no" => 0, "query_builder" => 1, "native" => 2, "query_builder_and_native" => 3 }.freeze
      APP_LEVELS = { "no" => 0, "yes" => 1 }.freeze

      def initialize(user)
        @user = user
        @groups = user&.groups&.to_a || []
      end

      def admin?
        @groups.any? { |g| g.system_group == "administrators" }
      end

      def collection_access(collection)
        return :curate if admin?

        levels = @groups.filter_map do |group|
          perm = Nquery::CollectionPermission.find_by(group: group, collection: collection)
          perm&.access_level
        end
        max_level(levels, COLLECTION_LEVELS)&.to_sym || :no_access
      end

      def data_access(data_source, resource_path: nil, permission_type: "view_data")
        return highest_data_level(permission_type) if admin?

        levels = @groups.flat_map do |group|
          Nquery::DataPermission.where(group: group, data_source: data_source, permission_type: permission_type)
                              .where("resource_path IS NULL OR resource_path = ?", resource_path)
                              .pluck(:access_level)
        end
        max_data_level(levels, permission_type)
      end

      def application_access(feature)
        return :yes if admin?

        levels = @groups.filter_map do |group|
          Nquery::ApplicationPermission.find_by(group: group, feature: feature)&.access_level
        end
        (max_level(levels, APP_LEVELS) || "no").to_sym
      end

      def all_users_more_permissive?(group, collection: nil, data_source: nil)
        all_users = Nquery::Group.find_by(system_group: "all_users")
        return false unless all_users

        if collection
          all_users_level = Nquery::CollectionPermission.find_by(group: all_users, collection: collection)&.access_level
          group_level = Nquery::CollectionPermission.find_by(group: group, collection: collection)&.access_level
          return COLLECTION_LEVELS[all_users_level].to_i > COLLECTION_LEVELS[group_level].to_i
        end

        false
      end

      private

      def max_level(levels, map)
        levels.max_by { |l| map[l] || -1 }
      end

      def max_data_level(levels, permission_type)
        map = permission_type == "create_queries" ? CREATE_QUERY_LEVELS : DATA_VIEW_LEVELS
        (max_level(levels, map) || default_data_level(permission_type)).to_sym
      end

      def highest_data_level(permission_type)
        permission_type == "create_queries" ? :query_builder_and_native : :can_view
      end

      def default_data_level(permission_type)
        permission_type == "create_queries" ? "no" : "blocked"
      end
    end
  end
end
