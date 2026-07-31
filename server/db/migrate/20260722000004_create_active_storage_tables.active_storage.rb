# frozen_string_literal: true

class CreateActiveStorageTables < ActiveRecord::Migration[8.0]
  def change
    create_table :active_storage_blobs, id: :primary_key do |t|
      t.string :key, null: false
      t.string :filename, null: false
      t.string :content_type
      t.text :metadata
      t.string :service_name, null: false
      t.bigint :byte_size, null: false
      t.string :checksum
      t.datetime :created_at, null: false
    end

    create_table :active_storage_attachments, id: :primary_key do |t|
      t.string :name, null: false
      t.references :record, null: false, polymorphic: true, index: false
      t.references :blob, null: false
      t.datetime :created_at, null: false
    end

    create_table :active_storage_variant_records, id: :primary_key do |t|
      t.belongs_to :blob, null: false, index: false
      t.string :variation_digest, null: false
    end

    add_index :active_storage_blobs, :key, unique: true
    add_index :active_storage_attachments, %i[record_type record_id name blob_id],
              unique: true, name: "index_active_storage_attachments_uniqueness"
    add_index :active_storage_variant_records, %i[blob_id variation_digest],
              unique: true, name: "index_active_storage_variant_records_uniqueness"
  end
end
