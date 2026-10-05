# frozen_string_literal: true

require_relative "../../rails_helper"

RSpec.describe "Embed pages", type: :request do
  let(:admin) { Nquery::User.find_by!(email: "admin@nquery.dev") }
  let(:chart) { Nquery::Chart.find_by!(name: "Revenue by month") }
  let(:dashboard) { Nquery::Dashboard.find_by!(name: "Executive overview") }

  def enable_static_embedding!
    Nquery.configuration.static_embedding_enabled = true
  end

  def sign_chart_token(resource = chart, params: {})
    resource.update!(enable_embedding: true)
    Nquery::EmbedTokenService.sign(
      resource_type: resource.class.name,
      resource_id: resource.id,
      creator: admin,
      params: params
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

    context "when the statement already has a limit" do
      it "renders the query rows" do
        enable_static_embedding!
        chart.query.update!(statement: "SELECT 1 AS value LIMIT 1")
        result = sign_chart_token

        get "/embed/charts/show", params: { token: result[:signed_token] }

        expect(response).to have_http_status(:ok)
        expect(response.body).to include("[[1]]")
        expect(response.body).not_to include("This chart could not be loaded.")
      end
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

    it "does not apply dashboard parameters on a chart embed" do
      enable_static_embedding!
      result = sign_chart_token

      get "/embed/charts/show", params: {
        token: result[:signed_token],
        start_date: "2026-08-01",
        end_date: "2026-08-07"
      }

      expect(response).to have_http_status(:ok)
      expect(response.body).to include("2026-01")
      expect(response.body).not_to include("This chart could not be loaded.")
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

    context "when the dashboard declares date parameters" do
      let(:data_source) { chart.query.data_source }
      let(:collection) { chart.collection }
      let!(:filtered_dashboard) do
        Nquery::Dashboard.create!(
          name: "Parameter board",
          collection: collection,
          creator: admin,
          parameters: [
            { "name" => "start_date", "type" => "date", "default" => "2026-08-01" },
            { "name" => "end_date", "type" => "date", "default" => "2026-08-07" }
          ]
        )
      end
      let!(:filtered_chart) do
        query = Nquery::Query.create!(
          name: "Orders in range",
          statement: "SELECT 'range-match' AS label WHERE {{start_date}} <= '2026-08-03' AND {{end_date}} > '2026-08-03'",
          data_source: data_source,
          creator: admin,
          collection: collection
        )
        created = Nquery::Chart.create!(
          name: "Orders in range",
          query: query,
          collection: collection,
          creator: admin,
          visualization: { "type" => "table" }
        )
        filtered_dashboard.dashboard_cards.create!(chart: created, pos_x: 0, pos_y: 0, width: 6, height: 4)
        created
      end
      let!(:plain_chart) do
        query = Nquery::Query.create!(
          name: "Constant value",
          statement: "SELECT 1 AS value",
          data_source: data_source,
          creator: admin,
          collection: collection
        )
        created = Nquery::Chart.create!(
          name: "Constant value",
          query: query,
          collection: collection,
          creator: admin,
          visualization: { "type" => "number", "y" => "value" }
        )
        filtered_dashboard.dashboard_cards.create!(chart: created, pos_x: 6, pos_y: 0, width: 6, height: 4)
        created
      end

      before do
        filtered_chart
        plain_chart
      end

      it "applies query string dates only to cards that reference them" do
        enable_static_embedding!
        result = sign_chart_token(filtered_dashboard)

        get "/embed/dashboards/show", params: {
          token: result[:signed_token],
          start_date: "2026-08-01",
          end_date: "2026-08-07"
        }

        expect(response).to have_http_status(:ok)
        expect(response.body).to include("range-match")
        expect(response.body).to include("[[1]]")
      end

      it "leaves the opt-in card empty when the query string is outside the range" do
        enable_static_embedding!
        result = sign_chart_token(filtered_dashboard)

        get "/embed/dashboards/show", params: {
          token: result[:signed_token],
          start_date: "2026-01-01",
          end_date: "2026-01-15"
        }

        expect(response.body).not_to include("range-match")
        expect(response.body).to include("[[1]]")
        expect(response.body).not_to include("This chart could not be loaded.")
      end

      it "applies dates stored on the embed token" do
        enable_static_embedding!
        result = sign_chart_token(
          filtered_dashboard,
          params: { "start_date" => "2026-08-01", "end_date" => "2026-08-07" }
        )

        get "/embed/dashboards/show", params: { token: result[:signed_token] }

        expect(response.body).to include("range-match")
        expect(response.body).to include("[[1]]")
      end

      it "lets the query string override token params" do
        enable_static_embedding!
        result = sign_chart_token(
          filtered_dashboard,
          params: { "start_date" => "2026-01-01", "end_date" => "2026-01-15" }
        )

        get "/embed/dashboards/show", params: {
          token: result[:signed_token],
          start_date: "2026-08-01",
          end_date: "2026-08-07"
        }

        expect(response.body).to include("range-match")
        expect(response.body).to include("[[1]]")
      end

      it "ignores unknown query keys" do
        enable_static_embedding!
        result = sign_chart_token(filtered_dashboard)

        get "/embed/dashboards/show", params: {
          token: result[:signed_token],
          start_date: "2026-08-01",
          end_date: "2026-08-07",
          evil: "drop-me"
        }

        expect(response.body).to include("range-match")
        expect(response.body).to include("[[1]]")
        expect(response.body).not_to include("drop-me")
      end

      it "does not execute an injected date and still renders the other card" do
        enable_static_embedding!
        result = sign_chart_token(filtered_dashboard)
        injected = "2026-08-01'; DROP TABLE nquery_users"

        get "/embed/dashboards/show", params: {
          token: result[:signed_token],
          start_date: injected,
          end_date: "2026-08-07"
        }

        expect(response.body).not_to include(injected)
        expect(response.body).not_to include("DROP TABLE")
        expect(response.body).to include("This chart could not be loaded.")
        expect(response.body).to include("[[1]]")
      end

      it "does not execute a calendar date that does not exist" do
        enable_static_embedding!
        result = sign_chart_token(filtered_dashboard)

        get "/embed/dashboards/show", params: {
          token: result[:signed_token],
          start_date: "2026-02-31",
          end_date: "2026-08-07"
        }

        expect(response.body).not_to include("2026-02-31")
        expect(response.body).to include("This chart could not be loaded.")
        expect(response.body).to include("[[1]]")
      end

      it "uses declared defaults when the request and token omit them" do
        enable_static_embedding!
        result = sign_chart_token(filtered_dashboard)

        get "/embed/dashboards/show", params: { token: result[:signed_token] }

        expect(response.body).to include("range-match")
        expect(response.body).to include("[[1]]")
      end

      it "omits the dashboard title when titled is false" do
        enable_static_embedding!
        result = sign_chart_token(filtered_dashboard)

        get "/embed/dashboards/show", params: { token: result[:signed_token], titled: "false" }

        expect(response.body).not_to include("<h1>Parameter board</h1>")
        expect(response.body).to include("[[1]]")
      end
    end
  end
end
