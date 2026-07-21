# frozen_string_literal: true

module Nquery
  module Admin
    class DataSourcesController < BaseController
      def index
        @data_sources = DataSource.order(:name)
      end

      def new
        @data_source = DataSource.new(adapter: "postgresql")
      end

      def create
        @data_source = DataSource.new(data_source_params)
        if @data_source.save
          redirect_to admin_data_sources_path, notice: "Data source created."
        else
          render :new, status: :unprocessable_entity
        end
      end

      def edit
        @data_source = DataSource.find(params[:id])
      end

      def update
        @data_source = DataSource.find(params[:id])
        if @data_source.update(data_source_params)
          redirect_to admin_data_sources_path, notice: "Data source updated."
        else
          render :edit, status: :unprocessable_entity
        end
      end

      private

      def data_source_params
        params.require(:data_source).permit(:name, :adapter, :active, :connection_config)
      end
    end
  end
end
