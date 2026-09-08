# frozen_string_literal: true

module Nquery
  class QueriesController < ApplicationController
    before_action :set_query, only: :update
    before_action :authorize_query_collection!, only: :update
    before_action :set_data_source_for_run, only: %i[run schema]
    before_action :authorize_run_data_source!, only: %i[run schema]

    def update
      if @query.update(query_params)
        render json: { ok: true, notice: "Query saved." }
      else
        render json: { error: @query.errors.full_messages.to_sentence.presence || "Query could not be saved." },
               status: :unprocessable_content
      end
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
  end
end
