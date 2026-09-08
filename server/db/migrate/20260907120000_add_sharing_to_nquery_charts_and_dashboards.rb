# frozen_string_literal: true

class AddSharingToNqueryChartsAndDashboards < ActiveRecord::Migration[8.1]
  def change
    add_sharing_columns :nquery_charts
    add_sharing_columns :nquery_dashboards
  end

  private

  def add_sharing_columns(table)
    add_column table, :public_uuid, :string
    add_index table, :public_uuid, unique: true
    add_reference table, :made_public_by, foreign_key: { to_table: :nquery_users }
    add_column table, :public_shared_at, :datetime
    add_column table, :enable_embedding, :boolean, null: false, default: false
    add_column table, :embedding_params, :json, null: false, default: {}
  end
end
