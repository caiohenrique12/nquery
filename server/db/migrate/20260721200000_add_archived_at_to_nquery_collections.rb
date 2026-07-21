# frozen_string_literal: true

class AddArchivedAtToNqueryCollections < ActiveRecord::Migration[8.1]
  def change
    add_column :nquery_collections, :archived_at, :datetime
    add_index :nquery_collections, :archived_at
  end
end
