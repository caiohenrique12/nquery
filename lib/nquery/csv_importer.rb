# frozen_string_literal: true

require "csv"

module Nquery
  class CsvImporter
    class Error < StandardError; end

    def initialize(file:, name:, creator:, column_mapping: {})
      @file = file
      @name = name.presence || "Import #{Time.current.to_fs(:short)}"
      @creator = creator
      @column_mapping = column_mapping
    end

    def import
      raise Error, "No file provided" unless @file

      upload = CsvUpload.create!(
        name: @name,
        creator: @creator,
        status: "processing",
        column_mapping: @column_mapping
      )

      rows = CSV.read(@file.path, headers: true)
      table_name = "nquery_import_#{upload.id}"

      connection = ActiveRecord::Base.connection
      columns = infer_columns(rows.headers)
      create_import_table(connection, table_name, columns)
      insert_rows(connection, table_name, rows, columns)

      data_source = DataSource.create!(
        name: @name,
        adapter: connection.adapter_name.downcase.include?("postgres") ? "postgresql" : "rails",
        connection_config: { import_table: table_name }.to_json
      )

      upload.update!(status: "completed", column_mapping: columns)
      upload
    rescue StandardError => e
      upload&.update!(status: "failed")
      raise Error, e.message
    end

    private

    def infer_columns(headers)
      headers.map { |h| { source: h, target: h.parameterize(separator: "_"), type: "text" } }
    end

    def create_import_table(connection, table_name, columns)
      cols = columns.map { |c| "#{connection.quote_column_name(c[:target])} TEXT" }.join(", ")
      connection.execute("CREATE TABLE IF NOT EXISTS #{connection.quote_table_name(table_name)} (#{cols})")
    end

    def insert_rows(connection, table_name, rows, columns)
      rows.each do |row|
        values = columns.map { |c| connection.quote(row[c[:source]]) }
        col_names = columns.map { |c| connection.quote_column_name(c[:target]) }.join(", ")
        connection.execute(
          "INSERT INTO #{connection.quote_table_name(table_name)} (#{col_names}) VALUES (#{values.join(', ')})"
        )
      end
    end
  end
end
