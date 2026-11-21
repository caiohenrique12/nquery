# frozen_string_literal: true

require_relative "../../rails_helper"

RSpec.describe "Public links", type: :request do
  let(:admin) { Nquery::User.find_by!(email: "admin@nquery.dev") }
  let(:chart) { Nquery::Chart.find_by!(name: "Revenue by month") }
  let(:dashboard) { Nquery::Dashboard.find_by!(name: "Executive overview") }

  describe "GET /public/charts/:uuid" do
    it "renders a publicly shared chart" do
      Nquery.configuration.public_sharing_enabled = true
      chart.share_publicly!(user: admin)

      get "/public/charts/#{chart.public_uuid}"

      expect(response).to have_http_status(:ok)
      expect(response.body).to include(chart.name)
      expect(response.body).to include("2026-01")
      expect(response.headers["X-Frame-Options"]).to be_blank
    end

    it "returns not found when the chart is unshared" do
      Nquery.configuration.public_sharing_enabled = true
      chart.unshare_publicly!

      get "/public/charts/#{SecureRandom.uuid}"

      expect(response).to have_http_status(:not_found)
      expect(response.body).to include("This visualization is not available.")
    end

    it "returns not found when public sharing is disabled" do
      chart.share_publicly!(user: admin)

      get "/public/charts/#{chart.public_uuid}"

      expect(response).to have_http_status(:not_found)
    end

    it "returns not found when the chart is archived" do
      Nquery.configuration.public_sharing_enabled = true
      chart.share_publicly!(user: admin)
      chart.archive!

      get "/public/charts/#{chart.public_uuid}"

      expect(response).to have_http_status(:not_found)
    end

    it "does not execute a chart with no data source against another source" do
      Nquery.configuration.public_sharing_enabled = true
      query = Nquery::Query.create!(
        name: "Unsourced public query",
        statement: chart.query.statement,
        data_source: nil,
        creator: admin,
        collection: chart.collection
      )
      unsourced = Nquery::Chart.create!(
        name: "Unsourced public chart",
        query: query,
        collection: chart.collection,
        creator: admin,
        visualization: { "type" => "table" }
      )
      unsourced.update_columns(
        public_uuid: SecureRandom.uuid,
        public_shared_at: Time.current,
        made_public_by_id: admin.id
      )

      get "/public/charts/#{unsourced.public_uuid}"

      expect(response).to have_http_status(:ok)
      expect(response.body).to include("This chart could not be loaded.")
      expect(response.body).not_to include("2026-01")
    end

    it "does not expose raw database errors to visitors" do
      Nquery.configuration.public_sharing_enabled = true
      chart.share_publicly!(user: admin)
      allow_any_instance_of(Nquery::QueryRunner).to receive(:run).and_raise(
        Nquery::QueryRunner::Error, 'PG::UndefinedTable: relation "secret_table"'
      )

      get "/public/charts/#{chart.public_uuid}"

      expect(response).to have_http_status(:ok)
      expect(response.body).not_to include("secret_table")
      expect(response.body).not_to include("PG::UndefinedTable")
      expect(response.body).to include("This chart could not be loaded.")
    end
  end

  describe "GET /public/dashboards/:uuid" do
    it "renders a publicly shared dashboard" do
      Nquery.configuration.public_sharing_enabled = true
      dashboard.share_publicly!(user: admin)

      get "/public/dashboards/#{dashboard.public_uuid}"

      expect(response).to have_http_status(:ok)
      expect(response.body).to include(dashboard.name)
      expect(response.body).to include(chart.name)
      expect(response.body).to include("nq-embed-grid")
    end

    it "returns not found when public sharing is disabled" do
      dashboard.share_publicly!(user: admin)

      get "/public/dashboards/#{dashboard.public_uuid}"

      expect(response).to have_http_status(:not_found)
    end

    it "returns not found when the dashboard is archived" do
      Nquery.configuration.public_sharing_enabled = true
      dashboard.share_publicly!(user: admin)
      dashboard.archive!

      get "/public/dashboards/#{dashboard.public_uuid}"

      expect(response).to have_http_status(:not_found)
    end

    context "when the dashboard declares a date default" do
      let(:data_source) { chart.query.data_source }
      let(:collection) { chart.collection }
      let!(:dated_dashboard) do
        Nquery::Dashboard.create!(
          name: "Public dated board",
          collection: collection,
          creator: admin,
          parameters: [
            { "name" => "start_date", "type" => "date", "default" => "2026-08-01" }
          ]
        )
      end
      let!(:dated_card) do
        query = Nquery::Query.create!(
          name: "Public bound by default",
          statement: "SELECT CASE WHEN {{start_date}} = '2026-08-01' THEN 'default-bound' ELSE 'query-string-bound' END AS label",
          data_source: data_source,
          creator: admin,
          collection: collection
        )
        created = Nquery::Chart.create!(
          name: "Public bound by default",
          query: query,
          collection: collection,
          creator: admin,
          visualization: { "type" => "table" }
        )
        dated_dashboard.dashboard_cards.create!(chart: created, pos_x: 0, pos_y: 0, width: 6, height: 4)
      end

      before do
        Nquery.configuration.public_sharing_enabled = true
        dated_card
        dated_dashboard.share_publicly!(user: admin)
      end

      it "renders the row bound to the saved default" do
        get "/public/dashboards/#{dated_dashboard.public_uuid}"

        expect(response.body).to include("default-bound")
        expect(response.body).not_to include("query-string-bound")
      end

      it "binds the saved date when the chart has no stored parameter" do
        bare = Nquery::Query.create!(
          name: "Public placeholder only",
          statement: "SELECT CASE WHEN {{start_date}} = '2026-08-01' THEN 'default-bound' ELSE 'query-string-bound' END AS label",
          data_source: data_source,
          creator: admin,
          collection: collection
        )
        bare_chart = Nquery::Chart.create!(
          name: "Public placeholder only",
          query: bare,
          collection: collection,
          creator: admin,
          visualization: { "type" => "table" }
        )
        board = Nquery::Dashboard.create!(
          name: "Public placeholder board",
          collection: collection,
          creator: admin,
          parameters: [{ "name" => "start_date", "type" => "date", "default" => "2026-08-01" }]
        )
        board.dashboard_cards.create!(chart: bare_chart, pos_x: 0, pos_y: 0, width: 6, height: 4)
        board.share_publicly!(user: admin)
        expect(bare.reload.parameters).to eq([])

        get "/public/dashboards/#{board.public_uuid}"

        expect(response.body).to include("default-bound")
        expect(response.body).not_to include("query-string-bound")
        expect(response.body).not_to include("This chart could not be loaded.")
        expect(board.reload.parameter_definitions.first).to include("type" => "date", "default" => "2026-08-01")
      end

      it "binds an agreed stored integer from the linked chart" do
        query = Nquery::Query.create!(
          name: "Public integer chart",
          statement: "SELECT CASE WHEN {{start_date}} = 4 THEN 'integer-bound' ELSE 'date-bound' END AS label",
          data_source: data_source,
          creator: admin,
          collection: collection,
          parameters: [{ "name" => "start_date", "type" => "integer", "default" => "4" }]
        )
        integer_chart = Nquery::Chart.create!(
          name: "Public integer chart",
          query: query,
          collection: collection,
          creator: admin,
          visualization: { "type" => "table" }
        )
        board = Nquery::Dashboard.create!(
          name: "Public integer board",
          collection: collection,
          creator: admin,
          parameters: [{ "name" => "start_date", "type" => "date", "default" => "2026-08-01" }]
        )
        board.dashboard_cards.create!(chart: integer_chart, pos_x: 0, pos_y: 0, width: 6, height: 4)
        board.share_publicly!(user: admin)

        get "/public/dashboards/#{board.public_uuid}"

        expect(response.body).to include("integer-bound")
        expect(response.body).not_to include("date-bound")
        expect(board.reload.parameter_definitions.first).to include("type" => "date", "default" => "2026-08-01")
      end

      it "ignores a query-string date" do
        get "/public/dashboards/#{dated_dashboard.public_uuid}", params: { start_date: "2026-01-01" }

        expect(response.body).to include("default-bound")
        expect(response.body).not_to include("query-string-bound")
      end
    end

    context "when a declared parameter has no default" do
      let(:data_source) { chart.query.data_source }
      let(:collection) { chart.collection }
      let!(:undated_dashboard) do
        Nquery::Dashboard.create!(
          name: "Public undated board",
          collection: collection,
          creator: admin,
          parameters: [
            { "name" => "start_date", "type" => "date", "default" => "" }
          ]
        )
      end
      let!(:undated_card) do
        query = Nquery::Query.create!(
          name: "Public missing default",
          statement: "SELECT 'should-not-run' AS label WHERE {{start_date}} = '2026-08-01'",
          data_source: data_source,
          creator: admin,
          collection: collection
        )
        created = Nquery::Chart.create!(
          name: "Public missing default",
          query: query,
          collection: collection,
          creator: admin,
          visualization: { "type" => "table" }
        )
        undated_dashboard.dashboard_cards.create!(chart: created, pos_x: 0, pos_y: 0, width: 6, height: 4)
      end

      before do
        Nquery.configuration.public_sharing_enabled = true
        undated_card
        undated_dashboard.share_publicly!(user: admin)
      end

      it "shows the load error" do
        get "/public/dashboards/#{undated_dashboard.public_uuid}"

        expect(response.body).to include("Enter a value for Start date.")
        expect(response.body).not_to include("This chart could not be loaded.")
        expect(response.body).not_to include("Jan")
        expect(response.body).not_to include("1200")
        expect(response.body).not_to include("should-not-run")
      end
    end
  end
end
