# frozen_string_literal: true

class AddKeyToNqueryDataSources < ActiveRecord::Migration[8.0]
  def change
    add_column :nquery_data_sources, :key, :string
    add_index :nquery_data_sources, :key, unique: true
  end
end
