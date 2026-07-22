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
      expect(response.body).to include('data-controller="chart-builder"')
      expect(response.body).to include("Format SQL")
      expect(response.body).to include("Run query")
      expect(response.body).to include("nq-sql-editor-shell")
      expect(response.body).to include("nq-sql-editor-hint")
      expect(response.body).to include("nq-sql-save-status")
      expect(response.body).to include('data-chart-builder-target="formatButton"')
      expect(response.body).to include("nq-schema-toggle")
      expect(response.body).to include("nq-schema-column-type")
      expect(response.body).to include("Output")
      expect(response.body).to include('class="nq-output-tab is-active"')
      expect(response.body).to include('data-tab="chart"')
      expect(response.body).to include("Save chart")
      expect(response.body).not_to include("data-query-save-url=")
      expect(response.body).not_to include('data-controller="query-editor"')
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
      expect(response).to redirect_to("/charts/#{chart.id}/edit")
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
      expect(response.body).to include('data-controller="chart-builder"')
      expect(response.body).to include("Output")
      expect(response.body).to include('data-tab="chart"')
      expect(response.body).not_to include('data-controller="query-editor"')
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
      expect(response).to redirect_to("/dashboards/#{dashboard.id}/charts/#{chart.id}/edit")
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

  describe "GET /dashboards/:dashboard_id/charts/:id/edit" do
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
      get "/dashboards/#{dashboard.id}/charts/#{chart.id}/edit"

      expect(response).to have_http_status(:ok)
    end

    it "renders the same chart builder form as new" do
      get "/dashboards/#{dashboard.id}/charts/#{chart.id}/edit"

      expect(response.body).to include("Edit chart")
      expect(response.body).to include('data-controller="chart-builder"')
      expect(response.body).to include("Format SQL")
      expect(response.body).to include("Run query")
      expect(response.body).to include("nq-sql-editor-shell")
      expect(response.body).to include("nq-sql-editor-hint")
      expect(response.body).to include("nq-sql-save-status")
      expect(response.body).to include('data-chart-builder-target="formatButton"')
      expect(response.body).to include("data-query-save-url=\"/queries/#{chart.query.id}\"")
      expect(response.body).to include("nq-schema-toggle")
      expect(response.body).to include("nq-schema-column-type")
      expect(response.body).to include("Output")
      expect(response.body).to include("Save chart")
      expect(response.body).to include("SELECT 1 AS value")
      expect(response.body).to include('value="bar"')
      expect(response.body).not_to include('data-controller="query-editor"')
      expect(response.body).not_to include('data-controller="chart-preview"')
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

    it "updates the chart and redirects to the nested edit page" do
      patch "/dashboards/#{dashboard.id}/charts/#{chart.id}", params: {
        chart: {
          name: "Signups updated",
          query_attributes: {
            id: chart.query.id,
            name: "Signups updated",
            statement: "SELECT 2 AS value",
            data_source_id: data_source.id
          },
          visualization: { type: "line", x: "value", y: "value" }
        }
      }

      expect(response).to redirect_to("/dashboards/#{dashboard.id}/charts/#{chart.id}/edit")
      expect(chart.reload.name).to eq("Signups updated")
      expect(chart.query.statement).to eq("SELECT 2 AS value")
      expect(chart.visualization["type"]).to eq("line")
    end

    it "updates the chart via turbo stream without redirecting" do
      patch "/dashboards/#{dashboard.id}/charts/#{chart.id}",
            params: {
              chart: {
                name: "Signups streamed",
                query_attributes: {
                  id: chart.query.id,
                  name: "Signups streamed",
                  statement: "SELECT 3 AS value",
                  data_source_id: data_source.id
                },
                visualization: { type: "bar", x: "value", y: "value" }
              }
            },
            as: :turbo_stream

      expect(response).to have_http_status(:ok)
      expect(response.media_type).to eq(Mime[:turbo_stream])
      expect(response.body).to include('turbo-stream action="update" target="flash"')
      expect(response.body).to include("Chart updated.")
      expect(chart.reload.name).to eq("Signups streamed")
      expect(chart.query.statement).to eq("SELECT 3 AS value")
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
