# frozen_string_literal: true

module Nquery
  class DashboardsController < ApplicationController
    include ChartResults
    include Browsable
    include SharingPage

    before_action :set_dashboard, only: %i[show edit update destroy archive unarchive update_layout embed connect_parameter]
    before_action :authorize_dashboard_view!, only: %i[show embed]
    before_action :authorize_dashboard_curate!, only: %i[edit update destroy archive unarchive update_layout connect_parameter]

    def index
      @dashboards = filter_viewable_dashboards(Dashboard.active.includes(:collection).order(:name))
      @collections = assignable_collections
    end

    def new
      @collections = assignable_collections
      if @collections.empty?
        redirect_to dashboards_path, alert: "You do not have permission to create a dashboard."
        return
      end
      @dashboard = Dashboard.new(collection: default_dashboard_collection)
    end

    def create
      @collections = assignable_collections
      @dashboard = Dashboard.new(dashboard_params.merge(creator: current_nquery_user))
      authorize_collection_access!(@dashboard.collection, required: :curate) if @dashboard.collection
      return if performed?

      if @dashboard.save
        redirect_to dashboard_path(@dashboard), notice: "Dashboard created."
      else
        render :new, status: :unprocessable_content
      end
    end

    def show
      assign_dashboard_filters
    end

    def embed
      assign_sharing_page(@dashboard)
    end

    def edit
      @collections = assignable_collections
    end

    def update
      @collections = assignable_collections
      authorize_collection_access!(Collection.find(dashboard_params[:collection_id]), required: :curate) if dashboard_params[:collection_id].present?

      previous_names = @dashboard.parameter_names
      if @dashboard.update(dashboard_params)
        added = @dashboard.parameter_names - previous_names
        if parameter_submission? && added.one?
          redirect_to dashboard_path(@dashboard, edit: "parameters", wire: added.first), notice: "Filter added."
        elsif parameter_submission? && params[:edit] == "parameters"
          redirect_to dashboard_path(@dashboard, **wire_query), notice: "Dashboard updated."
        else
          redirect_to dashboard_path(@dashboard), notice: "Dashboard updated."
        end
      elsif parameter_submission?
        assign_dashboard_filters
        render :show, status: :unprocessable_content
      else
        render :edit, status: :unprocessable_content
      end
    end

    def destroy
      @dashboard.destroy
      redirect_to dashboards_path, notice: "Dashboard removed."
    end

    def archive
      @dashboard.archive!
      redirect_to dashboards_path, notice: "Dashboard archived."
    end

    def unarchive
      @dashboard.unarchive!
      redirect_to dashboard_path(@dashboard), notice: "Dashboard unarchived."
    end

    def connect_parameter
      Dashboards::ParameterCharts.call(
        dashboard: @dashboard,
        name: params[:name],
        chart_ids: params.permit(chart_ids: []).fetch(:chart_ids, [])
      )
      redirect_to dashboard_path(@dashboard, **wire_query), notice: "Filter connected."
    end

    def update_layout
      card_layouts.each do |card_id, layout|
        card = @dashboard.dashboard_cards.find(card_id)
        card.update(pos_x: layout[:x], pos_y: layout[:y], width: layout[:w], height: layout[:h])
      end
      head :ok
    end

    private

    def set_dashboard
      @dashboard = if action_name.in?(%w[show edit embed])
                     Dashboard.includes(:creator, dashboard_cards: :chart).find(params[:id])
                   else
                     Dashboard.find(params[:id])
                   end
    end

    def authorize_dashboard_view!
      authorize_collection_access!(@dashboard.collection, required: :view)
    end

    def authorize_dashboard_curate!
      authorize_collection_access!(@dashboard.collection, required: :curate)
    end

    def card_layouts
      params.permit(cards: {}).fetch(:cards, {}).transform_values do |layout|
        layout.permit(:x, :y, :w, :h).to_h.symbolize_keys
      end
    end

    def assign_dashboard_filters
      filters = ::Nquery::Dashboards::Filters.call(dashboard: @dashboard, request_params: params)
      @filter_dashboard = filters.filter_dashboard
      @invalid_parameter_names = filters.parameters.invalid_names
      @dashboard_cards = @dashboard.dashboard_cards
        .joins(:chart)
        .merge(Chart.active)
        .includes(chart: { query: :data_source })
      @card_results = @dashboard_cards.index_with do |card|
        chart_result(card.chart, parameters: @dashboard.parameters_for_chart(card.chart, filters.parameters))
      end
    end

    def parameter_submission?
      params[:dashboard]&.key?(:parameters)
    end

    def wire_query
      { edit: params[:edit].presence, wire: params[:wire].presence }.compact
    end

    def dashboard_params
      permitted = params.require(:dashboard).permit(
        :name, :description, :collection_id, settings: {}, parameters: [:name, :type, :default, { chart_ids: [] }]
      )
      Dashboards::ParameterRows.call(dashboard: @dashboard, attributes: permitted)
    end

    def default_dashboard_collection
      root = Collection.roots.first
      return root if root && @collections.include?(root)

      @collections.first
    end
  end
end
