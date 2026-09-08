# frozen_string_literal: true

class RemoveEmbeddingParamsFromNqueryChartsAndDashboards < ActiveRecord::Migration[8.1]
  def change
    remove_column :nquery_charts, :embedding_params, :json, null: false, default: {}
    remove_column :nquery_dashboards, :embedding_params, :json, null: false, default: {}
  end
end
