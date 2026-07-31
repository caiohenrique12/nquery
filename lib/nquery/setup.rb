# frozen_string_literal: true

module Nquery
  class Setup
    ROOT_COLLECTION_NAME = "Our analytics"

    def self.run!
      new.run!
    end

    def run!
      admin_group = ensure_group!("Administrators", "administrators")
      all_users_group = ensure_group!("All Users", "all_users")

      DataSources::Syncer.call

      root_collection = Collection.find_or_create_by!(name: ROOT_COLLECTION_NAME, kind: "root")
      data_source = default_data_source

      seed_permissions!(admin_group, all_users_group, root_collection, data_source)
    end

    private

    def ensure_group!(name, system_group, description = nil)
      Group.find_or_create_by!(system_group: system_group) do |group|
        group.name = name
        group.description = description
      end
    end

    def default_data_source
      key = Nquery.configuration.default_data_source.to_s
      DataSource.find_by!(key: key)
    end

    def seed_permissions!(admin_group, all_users_group, root_collection, data_source)
      CollectionPermission.find_or_create_by!(group: admin_group, collection: root_collection) do |permission|
        permission.access_level = "curate"
      end
      CollectionPermission.find_or_create_by!(group: all_users_group, collection: root_collection) do |permission|
        permission.access_level = "view"
      end

      [admin_group, all_users_group].each do |group|
        view_level = "can_view"
        create_level = group.system_group == "administrators" ? "query_builder_and_native" : "no"

        DataPermission.find_or_create_by!(
          group: group,
          data_source: data_source,
          permission_type: "view_data",
          resource_path: nil
        ) do |permission|
          permission.access_level = view_level
        end

        DataPermission.find_or_create_by!(
          group: group,
          data_source: data_source,
          permission_type: "create_queries",
          resource_path: nil
        ) do |permission|
          permission.access_level = create_level
        end
      end

      ApplicationPermission::FEATURES.each do |feature|
        ApplicationPermission.find_or_create_by!(group: admin_group, feature: feature) do |permission|
          permission.access_level = "yes"
        end
      end
    end
  end
end
