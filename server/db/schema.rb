# This file is auto-generated from the current state of the database. Instead
# of editing this file, please use the migrations feature of Active Record to
# incrementally modify your database, and then regenerate this schema definition.
#
# This file is the source Rails uses to define your schema when running `bin/rails
# db:schema:load`. When creating a new database, `bin/rails db:schema:load` tends to
# be faster and is potentially less error prone than running all of your
# migrations from scratch. Old migrations may fail to apply correctly if those
# migrations use external dependencies or application code.
#
# It's strongly recommended that you check this file into your version control system.

ActiveRecord::Schema[8.1].define(version: 2026_07_22_000005) do
  create_table "active_storage_attachments", force: :cascade do |t|
    t.integer "blob_id", null: false
    t.datetime "created_at", null: false
    t.string "name", null: false
    t.integer "record_id", null: false
    t.string "record_type", null: false
    t.index ["blob_id"], name: "index_active_storage_attachments_on_blob_id"
    t.index ["record_type", "record_id", "name", "blob_id"], name: "index_active_storage_attachments_uniqueness", unique: true
  end

  create_table "active_storage_blobs", force: :cascade do |t|
    t.bigint "byte_size", null: false
    t.string "checksum"
    t.string "content_type"
    t.datetime "created_at", null: false
    t.string "filename", null: false
    t.string "key", null: false
    t.text "metadata"
    t.string "service_name", null: false
    t.index ["key"], name: "index_active_storage_blobs_on_key", unique: true
  end

  create_table "active_storage_variant_records", force: :cascade do |t|
    t.integer "blob_id", null: false
    t.string "variation_digest", null: false
    t.index ["blob_id", "variation_digest"], name: "index_active_storage_variant_records_uniqueness", unique: true
  end

  create_table "nquery_application_permissions", force: :cascade do |t|
    t.string "access_level", default: "no", null: false
    t.datetime "created_at", null: false
    t.string "feature", null: false
    t.bigint "group_id", null: false
    t.datetime "updated_at", null: false
    t.index ["group_id", "feature"], name: "index_nquery_application_permissions_on_group_id_and_feature", unique: true
    t.index ["group_id"], name: "index_nquery_application_permissions_on_group_id"
  end

  create_table "nquery_audits", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.integer "duration_ms"
    t.text "error_message"
    t.bigint "query_id"
    t.integer "row_count"
    t.text "statement"
    t.string "status", default: "success", null: false
    t.datetime "updated_at", null: false
    t.bigint "user_id"
    t.index ["query_id"], name: "index_nquery_audits_on_query_id"
    t.index ["user_id"], name: "index_nquery_audits_on_user_id"
  end

  create_table "nquery_charts", force: :cascade do |t|
    t.datetime "archived_at"
    t.bigint "collection_id"
    t.datetime "created_at", null: false
    t.bigint "creator_id"
    t.string "name", null: false
    t.bigint "query_id"
    t.datetime "updated_at", null: false
    t.json "visualization", default: {}, null: false
    t.index ["archived_at"], name: "index_nquery_charts_on_archived_at"
    t.index ["collection_id"], name: "index_nquery_charts_on_collection_id"
    t.index ["creator_id"], name: "index_nquery_charts_on_creator_id"
    t.index ["query_id"], name: "index_nquery_charts_on_query_id"
  end

  create_table "nquery_collection_permissions", force: :cascade do |t|
    t.string "access_level", default: "no_access", null: false
    t.bigint "collection_id", null: false
    t.datetime "created_at", null: false
    t.bigint "group_id", null: false
    t.datetime "updated_at", null: false
    t.index ["collection_id"], name: "index_nquery_collection_permissions_on_collection_id"
    t.index ["group_id", "collection_id"], name: "idx_on_group_id_collection_id_ca807a9a76", unique: true
    t.index ["group_id"], name: "index_nquery_collection_permissions_on_group_id"
  end

  create_table "nquery_collections", force: :cascade do |t|
    t.datetime "archived_at"
    t.datetime "created_at", null: false
    t.string "kind", default: "standard", null: false
    t.string "name", null: false
    t.bigint "owner_id"
    t.bigint "parent_id"
    t.datetime "updated_at", null: false
    t.index ["archived_at"], name: "index_nquery_collections_on_archived_at"
    t.index ["owner_id"], name: "index_nquery_collections_on_owner_id"
    t.index ["parent_id"], name: "index_nquery_collections_on_parent_id"
  end

  create_table "nquery_csv_uploads", force: :cascade do |t|
    t.json "column_mapping", default: {}, null: false
    t.datetime "created_at", null: false
    t.bigint "creator_id"
    t.string "name"
    t.string "status", default: "pending", null: false
    t.datetime "updated_at", null: false
    t.index ["creator_id"], name: "index_nquery_csv_uploads_on_creator_id"
  end

  create_table "nquery_dashboard_cards", force: :cascade do |t|
    t.bigint "chart_id", null: false
    t.datetime "created_at", null: false
    t.bigint "dashboard_id", null: false
    t.integer "height", default: 3, null: false
    t.integer "pos_x", default: 0, null: false
    t.integer "pos_y", default: 0, null: false
    t.datetime "updated_at", null: false
    t.integer "width", default: 4, null: false
    t.index ["chart_id"], name: "index_nquery_dashboard_cards_on_chart_id"
    t.index ["dashboard_id"], name: "index_nquery_dashboard_cards_on_dashboard_id"
  end

  create_table "nquery_dashboards", force: :cascade do |t|
    t.datetime "archived_at"
    t.bigint "collection_id"
    t.datetime "created_at", null: false
    t.bigint "creator_id"
    t.text "description"
    t.string "name", null: false
    t.json "settings", default: {}, null: false
    t.datetime "updated_at", null: false
    t.index ["archived_at"], name: "index_nquery_dashboards_on_archived_at"
    t.index ["collection_id"], name: "index_nquery_dashboards_on_collection_id"
    t.index ["creator_id"], name: "index_nquery_dashboards_on_creator_id"
  end

  create_table "nquery_data_permissions", force: :cascade do |t|
    t.string "access_level", null: false
    t.datetime "created_at", null: false
    t.bigint "data_source_id", null: false
    t.bigint "group_id", null: false
    t.string "permission_type", null: false
    t.string "resource_path"
    t.datetime "updated_at", null: false
    t.index ["data_source_id"], name: "index_nquery_data_permissions_on_data_source_id"
    t.index ["group_id", "data_source_id", "resource_path", "permission_type"], name: "index_nquery_data_permissions_unique", unique: true
    t.index ["group_id"], name: "index_nquery_data_permissions_on_group_id"
  end

  create_table "nquery_data_sources", force: :cascade do |t|
    t.boolean "active", default: true, null: false
    t.string "adapter", default: "postgresql", null: false
    t.text "connection_config"
    t.datetime "created_at", null: false
    t.string "key"
    t.string "name", null: false
    t.datetime "updated_at", null: false
    t.index ["key"], name: "index_nquery_data_sources_on_key", unique: true
  end

  create_table "nquery_embed_tokens", force: :cascade do |t|
    t.boolean "active", default: true, null: false
    t.datetime "created_at", null: false
    t.bigint "creator_id"
    t.datetime "expires_at"
    t.json "params", default: {}, null: false
    t.bigint "resource_id", null: false
    t.string "resource_type", null: false
    t.string "token", null: false
    t.datetime "updated_at", null: false
    t.index ["creator_id"], name: "index_nquery_embed_tokens_on_creator_id"
    t.index ["resource_type", "resource_id"], name: "index_nquery_embed_tokens_on_resource_type_and_resource_id"
    t.index ["token"], name: "index_nquery_embed_tokens_on_token", unique: true
  end

  create_table "nquery_group_memberships", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.bigint "group_id", null: false
    t.datetime "updated_at", null: false
    t.bigint "user_id", null: false
    t.index ["group_id"], name: "index_nquery_group_memberships_on_group_id"
    t.index ["user_id", "group_id"], name: "index_nquery_group_memberships_on_user_id_and_group_id", unique: true
    t.index ["user_id"], name: "index_nquery_group_memberships_on_user_id"
  end

  create_table "nquery_groups", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.text "description"
    t.string "name", null: false
    t.string "system_group", default: "custom", null: false
    t.datetime "updated_at", null: false
    t.index ["system_group"], name: "index_nquery_groups_on_system_group"
  end

  create_table "nquery_organizations", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.string "name", null: false
    t.datetime "onboarding_completed_at"
    t.datetime "updated_at", null: false
    t.string "website"
  end

  create_table "nquery_queries", force: :cascade do |t|
    t.bigint "collection_id"
    t.datetime "created_at", null: false
    t.bigint "creator_id"
    t.bigint "data_source_id"
    t.string "name"
    t.text "statement"
    t.datetime "updated_at", null: false
    t.index ["collection_id"], name: "index_nquery_queries_on_collection_id"
    t.index ["creator_id"], name: "index_nquery_queries_on_creator_id"
    t.index ["data_source_id"], name: "index_nquery_queries_on_data_source_id"
  end

  create_table "nquery_users", force: :cascade do |t|
    t.datetime "confirmation_sent_at"
    t.string "confirmation_token"
    t.datetime "confirmed_at"
    t.datetime "created_at", null: false
    t.datetime "deactivated_at"
    t.string "email", null: false
    t.string "encrypted_password", limit: 128
    t.string "external_id"
    t.string "first_name"
    t.string "last_name"
    t.string "password_digest"
    t.datetime "remember_created_at"
    t.datetime "reset_password_sent_at"
    t.string "reset_password_token"
    t.string "unconfirmed_email"
    t.datetime "updated_at", null: false
    t.index ["confirmation_token"], name: "index_nquery_users_on_confirmation_token", unique: true
    t.index ["email"], name: "index_nquery_users_on_email", unique: true
    t.index ["external_id"], name: "index_nquery_users_on_external_id", unique: true, where: "(external_id IS NOT NULL)"
    t.index ["reset_password_token"], name: "index_nquery_users_on_reset_password_token", unique: true
  end

  add_foreign_key "nquery_application_permissions", "nquery_groups", column: "group_id"
  add_foreign_key "nquery_audits", "nquery_queries", column: "query_id"
  add_foreign_key "nquery_audits", "nquery_users", column: "user_id"
  add_foreign_key "nquery_charts", "nquery_collections", column: "collection_id"
  add_foreign_key "nquery_charts", "nquery_queries", column: "query_id"
  add_foreign_key "nquery_charts", "nquery_users", column: "creator_id"
  add_foreign_key "nquery_collection_permissions", "nquery_collections", column: "collection_id"
  add_foreign_key "nquery_collection_permissions", "nquery_groups", column: "group_id"
  add_foreign_key "nquery_collections", "nquery_collections", column: "parent_id"
  add_foreign_key "nquery_collections", "nquery_users", column: "owner_id"
  add_foreign_key "nquery_csv_uploads", "nquery_users", column: "creator_id"
  add_foreign_key "nquery_dashboard_cards", "nquery_charts", column: "chart_id"
  add_foreign_key "nquery_dashboard_cards", "nquery_dashboards", column: "dashboard_id"
  add_foreign_key "nquery_dashboards", "nquery_collections", column: "collection_id"
  add_foreign_key "nquery_dashboards", "nquery_users", column: "creator_id"
  add_foreign_key "nquery_data_permissions", "nquery_data_sources", column: "data_source_id"
  add_foreign_key "nquery_data_permissions", "nquery_groups", column: "group_id"
  add_foreign_key "nquery_embed_tokens", "nquery_users", column: "creator_id"
  add_foreign_key "nquery_group_memberships", "nquery_groups", column: "group_id"
  add_foreign_key "nquery_group_memberships", "nquery_users", column: "user_id"
  add_foreign_key "nquery_queries", "nquery_collections", column: "collection_id"
  add_foreign_key "nquery_queries", "nquery_data_sources", column: "data_source_id"
  add_foreign_key "nquery_queries", "nquery_users", column: "creator_id"
end
