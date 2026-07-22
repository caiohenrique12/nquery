# frozen_string_literal: true

module Nquery
  class ImportsController < ApplicationController
    before_action :authorize_import_access!

    def new
      @csv_upload = CsvUpload.new
    end

    def create
      @csv_upload = CsvImporter.new(
        file: params[:file],
        name: params[:name],
        creator: current_nquery_user,
        column_mapping: parse_mapping(params[:column_mapping])
      ).import

      redirect_to root_path, notice: "CSV import started: #{@csv_upload.name}"
    rescue CsvImporter::Error => e
      @csv_upload = CsvUpload.new(name: params[:name])
      flash.now[:alert] = e.message
      render :new, status: :unprocessable_content
    end

    private

    def authorize_import_access!
      root = Collection.roots.first || Collection.shared.first
      authorize_collection_access!(root, required: :curate)
    end

    def parse_mapping(raw)
      return {} if raw.blank?

      JSON.parse(raw)
    rescue JSON::ParserError
      {}
    end
  end
end
