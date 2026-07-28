# frozen_string_literal: true

module Nquery
  module Admin
    class DataSourcesController < BaseController
      before_action :set_data_source, only: %i[edit update]

      def index
        @data_sources = DataSource.order(:name)
      end

      def new
        @data_source = DataSource.new(adapter: "postgresql")
      end

      def create
        @data_source = DataSource.new(data_source_params)
        @data_source.connection_fields_submitted = connection_fields_required?(@data_source.adapter)

        if @data_source.save
          redirect_to admin_data_sources_path, notice: "Data source created."
        else
          render :new, status: :unprocessable_content
        end
      end

      def edit
        @data_source.assign_connection_fields_from_config
      end

      def update
        @data_source.assign_attributes(data_source_params)
        @data_source.connection_fields_submitted = connection_fields_required?(@data_source.adapter)

        if @data_source.save
          redirect_to admin_data_sources_path, notice: "Data source updated."
        else
          @data_source.assign_connection_fields_from_config unless @data_source.connection_fields_submitted?
          render :edit, status: :unprocessable_content
        end
      end

      private

      def set_data_source
        @data_source = DataSource.find(params[:id])
      end

      def data_source_params
        params.require(:data_source).permit(
          :name,
          :adapter,
          :active,
          :host,
          :port,
          :database,
          :username,
          :password,
          :database_path,
          :sslmode
        )
      end

      def connection_fields_required?(adapter)
        DataSource::REMOTE_ADAPTERS.include?(adapter) || adapter == "sqlite"
      end
    end
  end
end
