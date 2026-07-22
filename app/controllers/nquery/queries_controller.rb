# frozen_string_literal: true

module Nquery
  class QueriesController < ApplicationController
    skip_before_action :_authenticate!, only: [] # always auth
    before_action :set_query, only: %i[show edit update]
    before_action :authorize_query_collection!, only: %i[show edit update]
    before_action :set_data_source_for_run, only: %i[run schema]
    before_action :authorize_run_data_source!, only: %i[run schema]

    def new
      @query = Query.new(statement: "SELECT 1 AS example")
      @data_sources = DataSource.active.order(:name)
      @schema_tables = schema_tables
    end

    def create
      @query = Query.new(query_params.merge(creator: current_nquery_user))
      if @query.save
        redirect_to edit_query_path(@query), notice: "Query created."
      else
        @data_sources = DataSource.active.order(:name)
        @schema_tables = schema_tables
        render :new, status: :unprocessable_content
      end
    end

    def edit
      @data_sources = DataSource.active.order(:name)
      @schema_tables = schema_tables
    end

    def update
      if @query.update(query_params)
        respond_to do |format|
          format.html { redirect_to edit_query_path(@query), notice: "Query saved." }
          format.json { render json: { ok: true, notice: "Query saved." } }
        end
      else
        @data_sources = DataSource.active.order(:name)
        @schema_tables = schema_tables
        respond_to do |format|
          format.html { render :edit, status: :unprocessable_content }
          format.json {
            render json: { error: @query.errors.full_messages.to_sentence.presence || "Query could not be saved." },
                   status: :unprocessable_content
          }
        end
      end
    end

    def show
    end

    def run
      result = QueryRunner.new(
        data_source: @data_source,
        statement: params[:statement],
        user: current_nquery_user
      ).run

      render json: result
    rescue QueryRunner::PermissionError => e
      render json: { error: e.message }, status: :forbidden
    rescue QueryRunner::Error => e
      render json: { error: e.message }, status: :unprocessable_content
    end

    def schema
      render json: { tables: Nquery::SchemaExplorer.tables_for(@data_source) }
    end

    private

    def set_query
      @query = Query.find(params[:id])
    end

    def authorize_query_collection!
      authorize_collection_access!(@query.collection, required: :view)
    end

    def set_data_source_for_run
      @data_source = DataSource.find(params[:data_source_id] || DataSource.first&.id)
    end

    def authorize_run_data_source!
      authorize_data_source_access!(@data_source, permission_type: "view_data")
      authorize_data_source_access!(@data_source, permission_type: "create_queries")
    end

    def query_params
      params.require(:query).permit(:name, :statement, :data_source_id, :collection_id)
    end

    def schema_tables
      data_source = DataSource.first
      return [] unless data_source

      DataSources::Adapter.for(data_source).tables
    rescue StandardError
      []
    end
  end
end
