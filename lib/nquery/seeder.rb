# frozen_string_literal: true

module Nquery
  class Seeder
    def self.run!
      new.run!
    end

    def run!
      admin_group = ensure_group!("Administrators", "administrators")
      all_users_group = ensure_group!("All Users", "all_users")
      engineering = ensure_group!("Engineering", "custom", "Engineering team")

      admin = ensure_user!("admin@nquery.dev", "Admin", "User", "password123")
      analyst = ensure_user!("analyst@nquery.dev", "Data", "Analyst", "password123")

      [admin, analyst].each(&:ensure_all_users_membership!)
      admin_group.group_memberships.find_or_create_by!(user: admin)
      engineering.group_memberships.find_or_create_by!(user: analyst)

      data_source = DataSource.find_or_create_by!(name: "Main Database") do |ds|
        ds.adapter = "rails"
        ds.connection_config = {}.to_json
      end

      root_collection = Collection.find_or_create_by!(name: "Our analytics", kind: "root")
      admin.ensure_personal_collection!

      seed_permissions!(admin_group, all_users_group, engineering, root_collection, data_source)

      query = Query.find_or_create_by!(name: "Monthly revenue") do |q|
        q.statement = "SELECT 'Jan' AS month, 1200 AS revenue UNION SELECT 'Feb', 1800 UNION SELECT 'Mar', 2400"
        q.data_source = data_source
        q.creator = admin
        q.collection = root_collection
      end

      chart = Chart.find_or_create_by!(name: "Revenue by month") do |c|
        c.query = query
        c.collection = root_collection
        c.creator = admin
        c.visualization = { "type" => "bar", "x" => "month", "y" => "revenue" }
      end

      dashboard = Dashboard.find_or_create_by!(name: "Executive overview") do |d|
        d.description = "Key metrics at a glance"
        d.collection = root_collection
        d.creator = admin
      end

      DashboardCard.find_or_create_by!(dashboard: dashboard, chart: chart) do |card|
        card.pos_x = 0
        card.pos_y = 0
        card.width = 6
        card.height = 4
      end

      EmbedTokenService.sign(
        resource_type: "Nquery::Chart",
        resource_id: chart.id,
        creator: admin,
        expires_at: 1.year.from_now
      ) unless EmbedToken.exists?(resource_type: "Nquery::Chart", resource_id: chart.id)

      ApplicationPermission::FEATURES.each do |feature|
        ApplicationPermission.find_or_create_by!(group: admin_group, feature: feature) do |p|
          p.access_level = "yes"
        end
      end
    end

    private

    def ensure_group!(name, system_group, description = nil)
      Group.find_or_create_by!(system_group: system_group) do |g|
        g.name = name
        g.description = description
      end
    end

    def ensure_user!(email, first_name, last_name, password)
      User.find_or_create_by!(email: email) do |u|
        u.first_name = first_name
        u.last_name = last_name
        u.password = password
      end
    end

    def seed_permissions!(admin_group, all_users_group, engineering, root_collection, data_source)
      CollectionPermission.find_or_create_by!(group: admin_group, collection: root_collection) do |p|
        p.access_level = "curate"
      end
      CollectionPermission.find_or_create_by!(group: all_users_group, collection: root_collection) do |p|
        p.access_level = "view"
      end
      CollectionPermission.find_or_create_by!(group: engineering, collection: root_collection) do |p|
        p.access_level = "view"
      end

      [admin_group, all_users_group, engineering].each do |group|
        level = group.system_group == "administrators" ? "can_view" : (group.system_group == "all_users" ? "can_view" : "blocked")
        create_level = group.system_group == "administrators" ? "query_builder_and_native" : "no"

        DataPermission.find_or_create_by!(group: group, data_source: data_source, permission_type: "view_data", resource_path: nil) do |p|
          p.access_level = level
        end
        DataPermission.find_or_create_by!(group: group, data_source: data_source, permission_type: "create_queries", resource_path: nil) do |p|
          p.access_level = create_level
        end
      end
    end
  end
end
