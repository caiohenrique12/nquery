# frozen_string_literal: true

module Nquery
  class Seeder
    def self.run!
      new.run!
    end

    def run!
      Setup.run!

      organization = Organization.find_or_create_by!(name: "Nquery Demo") do |org|
        org.website = "https://nquery.dev"
      end

      seed_sample_data!

      admin_group = Group.find_by!(system_group: "administrators")
      all_users_group = Group.find_by!(system_group: "all_users")
      engineering = ensure_group!("Engineering", "custom", "Engineering team")

      admin = ensure_user!("admin@nquery.dev", "Admin", "User", "password123")
      analyst = ensure_user!("analyst@nquery.dev", "Data", "Analyst", "password123")

      [admin, analyst].each(&:ensure_all_users_membership!)
      admin_group.group_memberships.find_or_create_by!(user: admin)
      engineering.group_memberships.find_or_create_by!(user: analyst)

      data_source = DataSource.find_by(key: "main") || DataSource.find_by!(name: "Application database")

      root_collection = Collection.find_or_create_by!(name: Setup::ROOT_COLLECTION_NAME, kind: "root")
      admin.ensure_personal_collection!

      seed_demo_permissions!(engineering, root_collection, data_source)

      sample_tables = SampleData::Ecommerce::TABLES
      query = Query.find_or_initialize_by(name: "Monthly revenue")
      query.assign_attributes(
        statement: <<~SQL.squish,
          SELECT strftime('%Y-%m', #{sample_tables[:orders]}.ordered_at) AS month,
                 ROUND(SUM(#{sample_tables[:order_items]}.quantity * #{sample_tables[:order_items]}.unit_price), 2) AS revenue
          FROM #{sample_tables[:orders]}
          INNER JOIN #{sample_tables[:order_items]} ON #{sample_tables[:order_items]}.order_id = #{sample_tables[:orders]}.id
          GROUP BY strftime('%Y-%m', #{sample_tables[:orders]}.ordered_at)
          ORDER BY month
        SQL
        data_source: data_source,
        creator: admin,
        collection: root_collection
      )
      query.save!

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

      organization.update!(onboarding_completed_at: Time.current) if organization.onboarding_completed_at.blank?
    end

    private

    def seed_sample_data!
      return unless Rails.env.local?

      SampleData::Ecommerce.run!
    end

    def ensure_group!(name, system_group, description = nil)
      Group.find_or_create_by!(system_group: system_group) do |g|
        g.name = name
        g.description = description
      end
    end

    def ensure_user!(email, first_name, last_name, password)
      User.find_or_create_by!(email: email) do |user|
        user.first_name = first_name
        user.last_name = last_name
        user.password = password
        user.password_confirmation = password
        user.confirmed_at = Time.current
      end.tap do |user|
        user.update!(confirmed_at: Time.current) if user.confirmed_at.blank?
      end
    end

    def seed_demo_permissions!(engineering, root_collection, data_source)
      CollectionPermission.find_or_create_by!(group: engineering, collection: root_collection) do |p|
        p.access_level = "view"
      end

      DataPermission.find_or_create_by!(group: engineering, data_source: data_source, permission_type: "view_data", resource_path: nil) do |p|
        p.access_level = "blocked"
      end
      DataPermission.find_or_create_by!(group: engineering, data_source: data_source, permission_type: "create_queries", resource_path: nil) do |p|
        p.access_level = "no"
      end
    end
  end
end
