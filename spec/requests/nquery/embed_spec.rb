# frozen_string_literal: true

require_relative "../../rails_helper"

RSpec.describe "Embed pages", type: :request do
  let(:admin) { Nquery::User.find_by!(email: "admin@nquery.dev") }
  let(:chart) { Nquery::Chart.find_by!(name: "Revenue by month") }
  let(:dashboard) { Nquery::Dashboard.find_by!(name: "Executive overview") }

  def enable_static_embedding!
    Nquery.configuration.static_embedding_enabled = true
  end

  def sign_chart_token(resource = chart)
    resource.update!(enable_embedding: true)
    Nquery::EmbedTokenService.sign(
      resource_type: resource.class.name,
      resource_id: resource.id,
      creator: admin
    )
  end

  describe "GET /embed/charts/show" do
    it "renders a chart with a valid token and real query data" do
      enable_static_embedding!
      result = sign_chart_token

      get "/embed/charts/show", params: { token: result[:signed_token] }

      expect(response).to have_http_status(:ok)
      expect(response.body).to include(chart.name)
      expect(response.body).to include("2026-01")
      expect(response.body).not_to include("Jan")
    end

    it "does not execute a chart with no data source against another source" do
      enable_static_embedding!
      query = Nquery::Query.create!(
        name: "Unsourced embed query",
        statement: chart.query.statement,
        data_source: nil,
        creator: admin,
        collection: chart.collection
      )
      unsourced = Nquery::Chart.create!(
        name: "Unsourced embed chart",
        query: query,
        collection: chart.collection,
        creator: admin,
        visualization: { "type" => "table" }
      )
      result = sign_chart_token(unsourced)

      get "/embed/charts/show", params: { token: result[:signed_token] }

      expect(response).to have_http_status(:ok)
      expect(response.body).to include("This chart could not be loaded.")
      expect(response.body).not_to include("2026-01")
    end

    it "rejects invalid tokens" do
      enable_static_embedding!

      get "/embed/charts/show", params: { token: "invalid.token" }

      expect(response).to have_http_status(:forbidden)
      expect(response.body).to include("Invalid or expired embed token")
    end

    it "rejects revoked tokens" do
      enable_static_embedding!
      result = sign_chart_token
      record = Nquery::EmbedToken.find_by!(token: result[:token])
      Nquery::EmbedTokenService.revoke!(record)

      get "/embed/charts/show", params: { token: result[:signed_token] }

      expect(response).to have_http_status(:forbidden)
      expect(response.body).to include("Invalid or expired embed token")
    end

    it "rejects tokens when embedding is disabled on the resource" do
      enable_static_embedding!
      result = sign_chart_token
      chart.update!(enable_embedding: false)

      get "/embed/charts/show", params: { token: result[:signed_token] }

      expect(response).to have_http_status(:forbidden)
      expect(response.body).to include("Embedding is disabled")
    end

    it "rejects tokens when static embedding is disabled" do
      result = sign_chart_token

      get "/embed/charts/show", params: { token: result[:signed_token] }

      expect(response).to have_http_status(:forbidden)
      expect(response.body).to include("Embedding is disabled")
    end

    it "rejects a dashboard token on the chart embed endpoint" do
      enable_static_embedding!
      result = sign_chart_token(dashboard)

      get "/embed/charts/show", params: { token: result[:signed_token] }

      expect(response).to have_http_status(:forbidden)
      expect(response.body).to include("Invalid or expired embed token")
    end

    it "rejects tokens when the chart is archived" do
      enable_static_embedding!
      result = sign_chart_token
      chart.archive!

      get "/embed/charts/show", params: { token: result[:signed_token] }

      expect(response).to have_http_status(:forbidden)
    end

    it "allows cross-origin framing" do
      enable_static_embedding!
      result = sign_chart_token

      get "/embed/charts/show", params: { token: result[:signed_token] }

      expect(response.headers["Content-Security-Policy"]).to eq("frame-ancestors *")
      expect(response.headers["X-Frame-Options"]).to be_blank
      expect(response.headers["X-Robots-Tag"]).to eq("noindex")
    end

    it "restricts frame ancestors when configured" do
      enable_static_embedding!
      Nquery.configuration.embed_frame_ancestors = ["https://wiki.example.com"]
      result = sign_chart_token

      get "/embed/charts/show", params: { token: result[:signed_token] }

      expect(response.headers["Content-Security-Policy"]).to eq("frame-ancestors https://wiki.example.com")
    end
  end

  describe "GET /embed/dashboards/show" do
    let!(:second_chart) do
      query = Nquery::Query.create!(
        name: "Orders count",
        statement: "SELECT COUNT(*) AS orders FROM nquery_sample_orders",
        data_source: chart.query.data_source,
        creator: admin,
        collection: chart.collection
      )
      extra = Nquery::Chart.create!(
        name: "Orders count",
        query: query,
        collection: chart.collection,
        creator: admin,
        visualization: { "type" => "number", "y" => "orders" }
      )
      dashboard.dashboard_cards.create!(chart: extra, pos_x: 6, pos_y: 0, width: 6, height: 4)
      extra
    end

    it "renders a dashboard grid with multiple cards" do
      enable_static_embedding!
      result = sign_chart_token(dashboard)

      get "/embed/dashboards/show", params: { token: result[:signed_token] }

      expect(response).to have_http_status(:ok)
      expect(response.body).to include(dashboard.name)
      expect(response.body).to include(chart.name)
      expect(response.body).to include(second_chart.name)
      expect(response.body).to include("nq-embed-grid")
      expect(response.body).to include("2026-01")
    end

    it "rejects invalid tokens" do
      enable_static_embedding!

      get "/embed/dashboards/show", params: { token: "invalid.token" }

      expect(response).to have_http_status(:forbidden)
      expect(response.body).to include("Invalid or expired embed token")
    end

    it "rejects tokens when the dashboard is archived" do
      enable_static_embedding!
      result = sign_chart_token(dashboard)
      dashboard.archive!

      get "/embed/dashboards/show", params: { token: result[:signed_token] }

      expect(response).to have_http_status(:forbidden)
    end

    it "rejects tokens when embedding is disabled on the dashboard" do
      enable_static_embedding!
      result = sign_chart_token(dashboard)
      dashboard.update!(enable_embedding: false)

      get "/embed/dashboards/show", params: { token: result[:signed_token] }

      expect(response).to have_http_status(:forbidden)
      expect(response.body).to include("Embedding is disabled")
    end

    it "rejects tokens when static embedding is disabled" do
      result = sign_chart_token(dashboard)

      get "/embed/dashboards/show", params: { token: result[:signed_token] }

      expect(response).to have_http_status(:forbidden)
      expect(response.body).to include("Embedding is disabled")
    end

    it "rejects a chart token on the dashboard embed endpoint" do
      enable_static_embedding!
      result = sign_chart_token(chart)

      get "/embed/dashboards/show", params: { token: result[:signed_token] }

      expect(response).to have_http_status(:forbidden)
      expect(response.body).to include("Invalid or expired embed token")
    end
  end
end
