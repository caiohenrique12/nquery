# frozen_string_literal: true

class AddArchivedAtToNqueryCharts < ActiveRecord::Migration[8.1]
  def change
    add_column :nquery_charts, :archived_at, :datetime
    add_index :nquery_charts, :archived_at
  end
end
