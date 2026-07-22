# frozen_string_literal: true

require_relative "../../rails_helper"

RSpec.describe Nquery::Breadcrumbs, type: :controller do
  controller(Nquery::ApplicationController) do
    include Nquery::Breadcrumbs

    def index
      render plain: "ok"
    end
  end

  before do
    routes.draw { get "index" => "anonymous#index" }
  end

  it "resolves breadcrumb collections from params" do
    collection = Nquery::Collection.roots.first
    controller.params = ActionController::Parameters.new(id: collection.id)

    expect(controller.send(:breadcrumb_collection)).to eq(collection)
  end

  it "resolves breadcrumb collections from the assigned collection" do
    collection = Nquery::Collection.roots.first
    controller.instance_variable_set(:@collection, collection)

    expect(controller.send(:breadcrumb_collection)).to eq(collection)
  end

  it "resolves parent collections from params" do
    collection = Nquery::Collection.roots.first
    controller.params = ActionController::Parameters.new(collection_id: collection.id)

    expect(controller.send(:breadcrumb_parent_collection)).to eq(collection)
  end

  it "resolves parent collections from the assigned parent collection" do
    collection = Nquery::Collection.roots.first
    controller.instance_variable_set(:@parent_collection, collection)

    expect(controller.send(:breadcrumb_parent_collection)).to eq(collection)
  end

  it "falls back to the assigned collection for parent breadcrumbs" do
    collection = Nquery::Collection.roots.first
    controller.instance_variable_set(:@collection, collection)

    expect(controller.send(:breadcrumb_parent_collection)).to eq(collection)
  end

  it "resolves dashboards and charts from params" do
    dashboard = Nquery::Dashboard.first
    chart = Nquery::Chart.first
    controller.params = ActionController::Parameters.new(dashboard_id: dashboard.id, id: chart.id)

    expect(controller.send(:breadcrumb_dashboard)).to eq(dashboard)
    expect(controller.send(:breadcrumb_chart)).to eq(chart)
  end

  it "resolves breadcrumb charts from the assigned chart" do
    chart = Nquery::Chart.first
    controller.instance_variable_set(:@chart, chart)

    expect(controller.send(:breadcrumb_chart)).to eq(chart)
  end
end
