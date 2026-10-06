# frozen_string_literal: true

class AddParametersToNqueryDashboards < ActiveRecord::Migration[8.1]
  def change
    add_column :nquery_dashboards, :parameters, :json, null: false, default: []
  end
end
