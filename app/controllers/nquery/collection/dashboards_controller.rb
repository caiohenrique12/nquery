# frozen_string_literal: true

module Nquery
  class Collection::DashboardsController < ApplicationController
    include Browsable

    before_action :set_collection
    before_action :authorize_collection_curate!

    def new
      @dashboard = Dashboard.new(collection: @collection)
    end

    def create
      @dashboard = Dashboard.new(dashboard_params.merge(collection: @collection, creator: current_nquery_user))

      if @dashboard.save
        redirect_to dashboard_path(@dashboard), notice: "Dashboard created."
      else
        render :new, status: :unprocessable_entity
      end
    end

    private

    def set_collection
      @collection = Collection.find(params[:collection_id])
    end

    def authorize_collection_curate!
      authorize_collection_access!(@collection, required: :curate)
    end

    def dashboard_params
      params.require(:dashboard).permit(:name, :description, settings: {})
    end
  end
end
