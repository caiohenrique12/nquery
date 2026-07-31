# frozen_string_literal: true

class CreateNqueryOrganizations < ActiveRecord::Migration[8.0]
  def change
    create_table :nquery_organizations do |t|
      t.string :name, null: false
      t.string :website
      t.timestamps
    end
  end
end
