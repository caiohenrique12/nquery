# frozen_string_literal: true

class AddParametersToNqueryQueries < ActiveRecord::Migration[8.1]
  def change
    add_column :nquery_queries, :parameters, :json, null: false, default: []
  end
end
