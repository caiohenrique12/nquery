# frozen_string_literal: true

class CreateNqueryTables < ActiveRecord::Migration[8.0]
  def change
    create_table :nquery_users do |t|
      t.string :email, null: false
      t.string :password_digest
      t.string :first_name
      t.string :last_name
      t.string :external_id
      t.datetime :deactivated_at
      t.timestamps
    end
    add_index :nquery_users, :email, unique: true
    add_index :nquery_users, :external_id, unique: true, where: "external_id IS NOT NULL"

    create_table :nquery_groups do |t|
      t.string :name, null: false
      t.string :system_group, null: false, default: "custom"
      t.text :description
      t.timestamps
    end
    add_index :nquery_groups, :system_group

    create_table :nquery_group_memberships do |t|
      t.references :user, null: false, foreign_key: { to_table: :nquery_users }
      t.references :group, null: false, foreign_key: { to_table: :nquery_groups }
      t.timestamps
    end
    add_index :nquery_group_memberships, %i[user_id group_id], unique: true

    create_table :nquery_data_sources do |t|
      t.string :name, null: false
      t.string :adapter, null: false, default: "postgresql"
      t.text :connection_config
      t.boolean :active, null: false, default: true
      t.timestamps
    end

    create_table :nquery_data_permissions do |t|
      t.references :group, null: false, foreign_key: { to_table: :nquery_groups }
      t.references :data_source, null: false, foreign_key: { to_table: :nquery_data_sources }
      t.string :resource_path
      t.string :permission_type, null: false
      t.string :access_level, null: false
      t.timestamps
    end
    add_index :nquery_data_permissions,
              %i[group_id data_source_id resource_path permission_type],
              unique: true,
              name: "index_nquery_data_permissions_unique"

    create_table :nquery_collections do |t|
      t.string :name, null: false
      t.string :kind, null: false, default: "standard"
      t.references :parent, foreign_key: { to_table: :nquery_collections }
      t.references :owner, foreign_key: { to_table: :nquery_users }
      t.timestamps
    end

    create_table :nquery_collection_permissions do |t|
      t.references :group, null: false, foreign_key: { to_table: :nquery_groups }
      t.references :collection, null: false, foreign_key: { to_table: :nquery_collections }
      t.string :access_level, null: false, default: "no_access"
      t.timestamps
    end
    add_index :nquery_collection_permissions, %i[group_id collection_id], unique: true

    create_table :nquery_application_permissions do |t|
      t.references :group, null: false, foreign_key: { to_table: :nquery_groups }
      t.string :feature, null: false
      t.string :access_level, null: false, default: "no"
      t.timestamps
    end
    add_index :nquery_application_permissions, %i[group_id feature], unique: true

    create_table :nquery_queries do |t|
      t.string :name
      t.text :statement
      t.references :data_source, foreign_key: { to_table: :nquery_data_sources }
      t.references :creator, foreign_key: { to_table: :nquery_users }
      t.references :collection, foreign_key: { to_table: :nquery_collections }
      t.timestamps
    end

    create_table :nquery_charts do |t|
      t.string :name, null: false
      t.references :query, foreign_key: { to_table: :nquery_queries }
      t.references :collection, foreign_key: { to_table: :nquery_collections }
      t.references :creator, foreign_key: { to_table: :nquery_users }
      t.json :visualization, null: false, default: {}
      t.timestamps
    end

    create_table :nquery_dashboards do |t|
      t.string :name, null: false
      t.text :description
      t.references :collection, foreign_key: { to_table: :nquery_collections }
      t.references :creator, foreign_key: { to_table: :nquery_users }
      t.json :settings, null: false, default: {}
      t.timestamps
    end

    create_table :nquery_dashboard_cards do |t|
      t.references :dashboard, null: false, foreign_key: { to_table: :nquery_dashboards }
      t.references :chart, null: false, foreign_key: { to_table: :nquery_charts }
      t.integer :pos_x, null: false, default: 0
      t.integer :pos_y, null: false, default: 0
      t.integer :width, null: false, default: 4
      t.integer :height, null: false, default: 3
      t.timestamps
    end

    create_table :nquery_csv_uploads do |t|
      t.string :name
      t.references :creator, foreign_key: { to_table: :nquery_users }
      t.string :status, null: false, default: "pending"
      t.json :column_mapping, null: false, default: {}
      t.timestamps
    end

    create_table :nquery_embed_tokens do |t|
      t.string :token, null: false
      t.string :resource_type, null: false
      t.bigint :resource_id, null: false
      t.references :creator, foreign_key: { to_table: :nquery_users }
      t.json :params, null: false, default: {}
      t.datetime :expires_at
      t.boolean :active, null: false, default: true
      t.timestamps
    end
    add_index :nquery_embed_tokens, :token, unique: true
    add_index :nquery_embed_tokens, %i[resource_type resource_id]

    create_table :nquery_audits do |t|
      t.references :user, foreign_key: { to_table: :nquery_users }
      t.references :query, foreign_key: { to_table: :nquery_queries }
      t.text :statement
      t.string :status, null: false, default: "success"
      t.integer :row_count
      t.integer :duration_ms
      t.text :error_message
      t.timestamps
    end
  end
end
