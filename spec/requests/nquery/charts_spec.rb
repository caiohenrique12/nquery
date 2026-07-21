# frozen_string_literal: true

require_relative "../../rails_helper"

RSpec.describe "Nquery::Charts", type: :request do
  let(:root_collection) { Nquery::Collection.roots.first }
  let(:admin) { Nquery::User.find_by!(email: "admin@nquery.dev") }
  let(:data_source) { Nquery::DataSource.find_by!(name: "Main Database") }

  let!(:dashboard) do
    Nquery::Dashboard.create!(
      name: "Ops overview",
      collection: root_collection,
      creator: admin
    )
  end

  def sign_in_as_admin
    post "/login", params: { email: admin.email, password: "password123" }
  end

  describe "GET /charts/new" do
    before { sign_in_as_admin }

    it "returns success" do
      get "/charts/new"

      expect(response).to have_http_status(:ok)
    end

    it "renders the new chart form" do
      get "/charts/new"

      expect(response.body).to include("New chart")
    end
  end

  describe "POST /charts" do
    before { sign_in_as_admin }

    it "creates a chart in the root collection" do
      expect {
        post "/charts", params: {
          chart: {
            name: "Standalone trend",
            query_attributes: {
              name: "Standalone trend",
              statement: "SELECT 1 AS value",
              data_source_id: data_source.id
            },
            visualization: { type: "bar", x: "value", y: "value" }
          }
        }
      }.to change(Nquery::Chart, :count).by(1)
        .and change(Nquery::Query, :count).by(1)

      chart = Nquery::Chart.find_by!(name: "Standalone trend")
      expect(chart.collection).to eq(root_collection)
      expect(response).to redirect_to("/charts/#{chart.id}")
    end
  end

  describe "GET /dashboards/:dashboard_id/charts/new" do
    before { sign_in_as_admin }

    it "returns success" do
      get "/dashboards/#{dashboard.id}/charts/new"

      expect(response).to have_http_status(:ok)
    end

    it "renders the new chart form" do
      get "/dashboards/#{dashboard.id}/charts/new"

      expect(response.body).to include("New chart")
    end
  end

  describe "POST /dashboards/:dashboard_id/charts" do
    before { sign_in_as_admin }

    it "creates a chart and attaches it to the dashboard" do
      expect {
        post "/dashboards/#{dashboard.id}/charts", params: {
          chart: {
            name: "Signups trend",
            query_attributes: {
              name: "Signups trend",
              statement: "SELECT 1 AS value",
              data_source_id: data_source.id
            },
            visualization: { type: "bar", x: "value", y: "value" }
          }
        }
      }.to change(Nquery::Chart, :count).by(1)
        .and change(Nquery::Query, :count).by(1)
        .and change(Nquery::DashboardCard, :count).by(1)

      chart = Nquery::Chart.find_by!(name: "Signups trend")
      expect(chart.collection).to eq(root_collection)
      expect(chart.dashboard_cards.first.dashboard).to eq(dashboard)
      expect(response).to redirect_to("/dashboards/#{dashboard.id}/charts/#{chart.id}")
    end
  end

  describe "GET /dashboards/:id" do
    before { sign_in_as_admin }

    it "links to nested new chart" do
      get "/dashboards/#{dashboard.id}"

      expect(response.body).to include("href=\"/dashboards/#{dashboard.id}/charts/new\"")
    end
  end

  describe "GET /dashboards/:dashboard_id/charts/:id" do
    let!(:chart) do
      query = Nquery::Query.create!(
        name: "Signups trend",
        statement: "SELECT 1 AS value",
        data_source: data_source,
        creator: admin,
        collection: root_collection
      )
      Nquery::Chart.create!(
        name: "Signups trend",
        query: query,
        collection: root_collection,
        creator: admin,
        visualization: { "type" => "bar", "x" => "value", "y" => "value" }
      ).tap do |created_chart|
        dashboard.dashboard_cards.create!(chart: created_chart, pos_x: 0, pos_y: 0, width: 6, height: 4)
      end
    end

    before { sign_in_as_admin }

    it "returns success" do
      get "/dashboards/#{dashboard.id}/charts/#{chart.id}"

      expect(response).to have_http_status(:ok)
      expect(response.body).to include("Signups trend")
    end

    it "links to nested edit and embed actions" do
      get "/dashboards/#{dashboard.id}/charts/#{chart.id}"

      expect(response.body).to include("href=\"/dashboards/#{dashboard.id}/charts/#{chart.id}/edit\"")
      expect(response.body).to include("href=\"/dashboards/#{dashboard.id}/charts/#{chart.id}/embed\"")
    end
  end

  describe "PATCH /dashboards/:dashboard_id/charts/:id" do
    let!(:chart) do
      query = Nquery::Query.create!(
        name: "Signups trend",
        statement: "SELECT 1 AS value",
        data_source: data_source,
        creator: admin,
        collection: root_collection
      )
      Nquery::Chart.create!(
        name: "Signups trend",
        query: query,
        collection: root_collection,
        creator: admin,
        visualization: { "type" => "bar", "x" => "value", "y" => "value" }
      ).tap do |created_chart|
        dashboard.dashboard_cards.create!(chart: created_chart, pos_x: 0, pos_y: 0, width: 6, height: 4)
      end
    end

    before { sign_in_as_admin }

    it "updates the chart and redirects to the nested show page" do
      patch "/dashboards/#{dashboard.id}/charts/#{chart.id}", params: {
        chart: { name: "Signups updated" }
      }

      expect(response).to redirect_to("/dashboards/#{dashboard.id}/charts/#{chart.id}")
      expect(chart.reload.name).to eq("Signups updated")
    end
  end

  describe "PATCH /dashboards/:dashboard_id/charts/:id/archive" do
    let!(:chart) do
      query = Nquery::Query.create!(
        name: "Signups trend",
        statement: "SELECT 1 AS value",
        data_source: data_source,
        creator: admin,
        collection: root_collection
      )
      Nquery::Chart.create!(
        name: "Signups trend",
        query: query,
        collection: root_collection,
        creator: admin,
        visualization: { "type" => "bar", "x" => "value", "y" => "value" }
      ).tap do |created_chart|
        dashboard.dashboard_cards.create!(chart: created_chart, pos_x: 0, pos_y: 0, width: 6, height: 4)
      end
    end

    before { sign_in_as_admin }

    it "archives the chart and redirects to the dashboard" do
      patch "/dashboards/#{dashboard.id}/charts/#{chart.id}/archive"

      expect(response).to redirect_to("/dashboards/#{dashboard.id}")
      expect(chart.reload.archived?).to be(true)
    end
  end

  describe "DELETE /dashboards/:dashboard_id/charts/:id" do
    let!(:chart) do
      query = Nquery::Query.create!(
        name: "Signups trend",
        statement: "SELECT 1 AS value",
        data_source: data_source,
        creator: admin,
        collection: root_collection
      )
      Nquery::Chart.create!(
        name: "Signups trend",
        query: query,
        collection: root_collection,
        creator: admin,
        visualization: { "type" => "bar", "x" => "value", "y" => "value" }
      ).tap do |created_chart|
        dashboard.dashboard_cards.create!(chart: created_chart, pos_x: 0, pos_y: 0, width: 6, height: 4)
      end
    end

    before { sign_in_as_admin }

    it "removes the chart and redirects to the dashboard" do
      expect {
        delete "/dashboards/#{dashboard.id}/charts/#{chart.id}"
      }.to change(Nquery::Chart, :count).by(-1)

      expect(response).to redirect_to("/dashboards/#{dashboard.id}")
    end
  end
end
