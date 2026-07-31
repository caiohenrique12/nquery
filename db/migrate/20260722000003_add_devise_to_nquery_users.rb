# frozen_string_literal: true

class AddDeviseToNqueryUsers < ActiveRecord::Migration[8.0]
  def change
    change_table :nquery_users, bulk: true do |t|
      t.string :encrypted_password, limit: 128
      t.string :reset_password_token
      t.datetime :reset_password_sent_at
      t.datetime :remember_created_at
      t.string :confirmation_token
      t.datetime :confirmed_at
      t.datetime :confirmation_sent_at
      t.string :unconfirmed_email
    end

    add_index :nquery_users, :reset_password_token, unique: true
    add_index :nquery_users, :confirmation_token, unique: true

    reversible do |dir|
      dir.up do
        execute <<~SQL.squish
          UPDATE nquery_users
          SET encrypted_password = password_digest
          WHERE encrypted_password IS NULL AND password_digest IS NOT NULL
        SQL

        execute <<~SQL.squish
          UPDATE nquery_users
          SET confirmed_at = CURRENT_TIMESTAMP
          WHERE confirmed_at IS NULL AND encrypted_password IS NOT NULL
        SQL
      end
    end
  end
end
