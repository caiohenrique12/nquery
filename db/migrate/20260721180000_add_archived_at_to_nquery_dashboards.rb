# frozen_string_literal: true

class AddArchivedAtToNqueryDashboards < ActiveRecord::Migration[8.1]
  def change
    add_column :nquery_dashboards, :archived_at, :datetime
    add_index :nquery_dashboards, :archived_at
  end
end
