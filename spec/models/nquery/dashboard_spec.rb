# frozen_string_literal: true

require_relative "../../rails_helper"

RSpec.describe Nquery::Dashboard do
  let(:root_collection) { Nquery::Collection.roots.first }
  let(:admin) { Nquery::User.find_by!(email: "admin@nquery.dev") }

  describe "validations" do
    it "requires a collection" do
      dashboard = described_class.new(name: "Ops overview", creator: admin)

      expect(dashboard).not_to be_valid
      expect(dashboard.errors[:collection]).to include("must exist")
    end

    it "is valid with a collection" do
      dashboard = described_class.new(
        name: "Ops overview",
        collection: root_collection,
        creator: admin
      )

      expect(dashboard).to be_valid
    end
  end

  describe "parameters" do
    def build_dashboard(parameters:)
      described_class.new(
        name: "Ops overview",
        collection: root_collection,
        creator: admin,
        parameters: parameters
      )
    end

    it "keeps the charts linked to a parameter" do
      chart = Nquery::Chart.create!(
        name: "Linked chart",
        collection: root_collection,
        creator: admin,
        visualization: { "type" => "table" }
      )
      dashboard = build_dashboard(
        parameters: [{ "name" => "start_date", "type" => "date", "default" => "", "chart_ids" => [chart.id.to_s, ""] }]
      )

      expect(dashboard).to be_valid
      expect(dashboard.parameter_definitions.first["chart_ids"]).to eq([chart.id])
      expect(dashboard.parameter_linked_to_chart?(dashboard.parameter_definitions.first, chart)).to be(true)
    end

    it "lists every chart that uses the variable when the parameter is not restricted" do
      dashboard = build_dashboard(
        parameters: [{ "name" => "start_date", "type" => "date", "default" => "" }]
      )
      dashboard.save!
      used = Nquery::Chart.create!(
        name: "Uses the variable",
        collection: root_collection,
        creator: admin,
        visualization: { "type" => "table" },
        query: Nquery::Query.create!(
          name: "Uses the variable",
          statement: "SELECT {{start_date}} AS start_date",
          data_source: Nquery::DataSource.find_by!(key: "main"),
          creator: admin,
          collection: root_collection
        )
      )
      ignored = Nquery::Chart.create!(
        name: "Ignores the variable",
        collection: root_collection,
        creator: admin,
        visualization: { "type" => "table" },
        query: Nquery::Query.create!(
          name: "Ignores the variable",
          statement: "SELECT 1 AS value",
          data_source: Nquery::DataSource.find_by!(key: "main"),
          creator: admin,
          collection: root_collection
        )
      )
      dashboard.dashboard_cards.create!(chart: used, pos_x: 0, pos_y: 0, width: 6, height: 4)
      dashboard.dashboard_cards.create!(chart: ignored, pos_x: 6, pos_y: 0, width: 6, height: 4)

      expect(dashboard.linked_chart_ids(dashboard.parameter_definitions.first)).to eq([used.id])
    end

    it "treats a parameter without chart ids as linked to every chart" do
      chart = Nquery::Chart.create!(
        name: "Any chart",
        collection: root_collection,
        creator: admin,
        visualization: { "type" => "table" }
      )
      dashboard = build_dashboard(
        parameters: [{ "name" => "start_date", "type" => "date", "default" => "2026-08-01" }]
      )
      resolved = Nquery::DashboardParameters::Result.new(
        values: { "start_date" => Date.new(2026, 8, 1) },
        invalid_names: []
      )

      expect(dashboard.parameter_linked_to_chart?(dashboard.parameter_definitions.first, chart)).to be(true)
      expect(dashboard.parameters_for_chart(chart, resolved).values["start_date"]).to eq(Date.new(2026, 8, 1))
    end

    it "accepts a date parameter with a default" do
      dashboard = build_dashboard(
        parameters: [{ "name" => "start_date", "type" => "date", "default" => "2026-08-01" }]
      )

      expect(dashboard).to be_valid
      dashboard.save!

      expect(dashboard.parameter_definitions).to eq(
        [{ "name" => "start_date", "type" => "date", "default" => "2026-08-01" }]
      )
      expect(dashboard.parameter_names).to eq(["start_date"])
    end

    it "accepts a blank default" do
      dashboard = build_dashboard(
        parameters: [{ "name" => "start_date", "type" => "date", "default" => "" }]
      )

      expect(dashboard).to be_valid
    end

    it "drops rows whose name is blank" do
      dashboard = build_dashboard(
        parameters: [
          { "name" => "  ", "type" => "date", "default" => "2026-08-01" },
          { "name" => "end_date", "type" => "date", "default" => "" }
        ]
      )

      expect(dashboard).to be_valid
      dashboard.save!

      expect(dashboard.parameter_names).to eq(["end_date"])
    end

    it "rejects a name that is not a lowercase identifier" do
      dashboard = build_dashboard(
        parameters: [{ "name" => "Start-Date", "type" => "date", "default" => "" }]
      )

      expect(dashboard).not_to be_valid
      expect(dashboard.errors[:parameters]).to be_present
    end

    it "rejects a duplicate name" do
      dashboard = build_dashboard(
        parameters: [
          { "name" => "start_date", "type" => "date", "default" => "" },
          { "name" => "start_date", "type" => "date", "default" => "2026-08-01" }
        ]
      )

      expect(dashboard).not_to be_valid
      expect(dashboard.errors[:parameters]).to be_present
    end

    %w[token titled bordered theme].each do |reserved|
      it "rejects the reserved name #{reserved}" do
        dashboard = build_dashboard(
          parameters: [{ "name" => reserved, "type" => "date", "default" => "" }]
        )

        expect(dashboard).not_to be_valid
        expect(dashboard.errors[:parameters]).to be_present
      end
    end

    %w[id wire action controller format].each do |reserved|
      it "rejects the reserved name #{reserved}" do
        dashboard = build_dashboard(
          parameters: [{ "name" => reserved, "type" => "string", "default" => "" }]
        )

        expect(dashboard).not_to be_valid
        expect(dashboard.errors[:parameters]).to include("cannot use #{reserved}")
      end
    end

    it "accepts string, integer, and datetime parameters" do
      dashboard = build_dashboard(
        parameters: [
          { "name" => "label", "type" => "string", "default" => "north" },
          { "name" => "minimum", "type" => "integer", "default" => "3" },
          { "name" => "as_of", "type" => "datetime", "default" => "2026-08-01T15:30" }
        ]
      )

      expect(dashboard).to be_valid
    end

    it "accepts a uuid parameter" do
      dashboard = build_dashboard(
        parameters: [{ "name" => "customer_id", "type" => "uuid", "default" => "550E8400-E29B-41D4-A716-446655440000" }]
      )

      expect(dashboard).to be_valid
    end

    it "rejects a uuid default that is not a uuid" do
      dashboard = build_dashboard(
        parameters: [{ "name" => "customer_id", "type" => "uuid", "default" => "not-a-uuid" }]
      )

      expect(dashboard).not_to be_valid
    end

    it "accepts a boolean parameter" do
      dashboard = build_dashboard(
        parameters: [{ "name" => "active", "type" => "boolean", "default" => "false" }]
      )

      expect(dashboard).to be_valid
    end

    it "rejects a boolean default that is not true or false" do
      dashboard = build_dashboard(
        parameters: [{ "name" => "active", "type" => "boolean", "default" => "maybe" }]
      )

      expect(dashboard).not_to be_valid
    end

    it "rejects an unknown parameter type" do
      dashboard = build_dashboard(
        parameters: [{ "name" => "start_date", "type" => "float", "default" => "" }]
      )

      expect(dashboard).not_to be_valid
      expect(dashboard.errors[:parameters]).to be_present
    end

    it "rejects an integer default that is not a whole number" do
      dashboard = build_dashboard(
        parameters: [{ "name" => "minimum", "type" => "integer", "default" => "1.5" }]
      )

      expect(dashboard).not_to be_valid
    end

    it "rejects a default that is not a real calendar date" do
      dashboard = build_dashboard(
        parameters: [{ "name" => "start_date", "type" => "date", "default" => "2026-02-31" }]
      )

      expect(dashboard).not_to be_valid
      expect(dashboard.errors[:parameters]).to be_present
    end

    it "rejects a default that is not an ISO date" do
      dashboard = build_dashboard(
        parameters: [{ "name" => "start_date", "type" => "date", "default" => "2026-08-01' OR '1'='1" }]
      )

      expect(dashboard).not_to be_valid
      expect(dashboard.errors[:parameters]).to be_present
    end
  end

  describe "#with_agreed_chart_variables" do
    let(:data_source) { Nquery::DataSource.find_by!(key: "main") }

    def build_dashboard(parameters:)
      described_class.create!(
        name: "Overlay board",
        collection: root_collection,
        creator: admin,
        parameters: parameters
      )
    end

    def chart_for(name:, statement:, parameters: [])
      Nquery::Chart.create!(
        name: name,
        collection: root_collection,
        creator: admin,
        visualization: { "type" => "table" },
        query: Nquery::Query.create!(
          name: name,
          statement: statement,
          parameters: parameters,
          data_source: data_source,
          creator: admin,
          collection: root_collection
        )
      )
    end

    it "keeps the dashboard default when the chart has no stored parameter" do
      dashboard = build_dashboard(
        parameters: [{ "name" => "start_date", "type" => "date", "default" => "2026-08-01" }]
      )
      chart = chart_for(name: "SQL only chart", statement: "SELECT {{start_date}} AS start_date")
      dashboard.dashboard_cards.create!(chart: chart, pos_x: 0, pos_y: 0, width: 6, height: 4)

      expect(chart.query.reload.parameters).to eq([])
      overlay = dashboard.with_agreed_chart_variables

      expect(overlay.parameter_definitions.first).to include("type" => "date", "default" => "2026-08-01")
      expect(dashboard.reload.parameter_definitions.first).to include("type" => "date", "default" => "2026-08-01")
    end

    it "overlays an agreed stored chart type and default" do
      dashboard = build_dashboard(
        parameters: [{ "name" => "start_date", "type" => "date", "default" => "2026-08-01" }]
      )
      first = chart_for(
        name: "First integer chart",
        statement: "SELECT {{start_date}} AS start_date",
        parameters: [{ "name" => "start_date", "type" => "integer", "default" => "4" }]
      )
      second = chart_for(
        name: "Second integer chart",
        statement: "SELECT {{start_date}} AS start_date",
        parameters: [{ "name" => "start_date", "type" => "integer", "default" => "4" }]
      )
      dashboard.dashboard_cards.create!(chart: first, pos_x: 0, pos_y: 0, width: 6, height: 4)
      dashboard.dashboard_cards.create!(chart: second, pos_x: 6, pos_y: 0, width: 6, height: 4)

      overlay = dashboard.with_agreed_chart_variables

      expect(overlay.parameter_definitions.first).to include("type" => "integer", "default" => "4")
      expect(dashboard.reload.parameter_definitions.first).to include("type" => "date", "default" => "2026-08-01")
    end

    it "loads charts once for every filter" do
      dashboard = build_dashboard(
        parameters: [
          { "name" => "start_date", "type" => "date", "default" => "2026-08-01" },
          { "name" => "end_date", "type" => "date", "default" => "2026-08-07" }
        ]
      )
      chart = chart_for(
        name: "Both dates",
        statement: "SELECT {{start_date}} AS start_date, {{end_date}} AS end_date",
        parameters: [
          { "name" => "start_date", "type" => "date", "default" => "" },
          { "name" => "end_date", "type" => "date", "default" => "" }
        ]
      )
      dashboard.dashboard_cards.create!(chart: chart, pos_x: 0, pos_y: 0, width: 6, height: 4)

      queries = []
      subscriber = ActiveSupport::Notifications.subscribe("sql.active_record") do |event|
        queries << event.payload[:sql]
      end
      dashboard.with_agreed_chart_variables
      ActiveSupport::Notifications.unsubscribe(subscriber)

      expect(queries.count { |sql| sql.match?(/FROM "?nquery_charts"?/) }).to eq(1)
    end

    it "keeps the dashboard default when stored chart parameters disagree" do
      dashboard = build_dashboard(
        parameters: [{ "name" => "start_date", "type" => "date", "default" => "2026-08-01" }]
      )
      integer_chart = chart_for(
        name: "Disagree integer chart",
        statement: "SELECT {{start_date}} AS start_date",
        parameters: [{ "name" => "start_date", "type" => "integer", "default" => "4" }]
      )
      string_chart = chart_for(
        name: "Disagree string chart",
        statement: "SELECT {{start_date}} AS start_date",
        parameters: [{ "name" => "start_date", "type" => "string", "default" => "north" }]
      )
      dashboard.dashboard_cards.create!(chart: integer_chart, pos_x: 0, pos_y: 0, width: 6, height: 4)
      dashboard.dashboard_cards.create!(chart: string_chart, pos_x: 6, pos_y: 0, width: 6, height: 4)

      expect { dashboard.with_agreed_chart_variables }.not_to raise_error
      expect(dashboard.with_agreed_chart_variables.parameter_definitions.first).to include(
        "type" => "date",
        "default" => "2026-08-01"
      )
    end
  end

  describe "archiving" do
    let(:dashboard) do
      described_class.create!(
        name: "Ops overview",
        collection: root_collection,
        creator: admin
      )
    end

    it "starts active" do
      expect(dashboard.archived?).to be(false)
      expect(described_class.active).to include(dashboard)
      expect(described_class.archived).not_to include(dashboard)
    end

    it "archives and unarchives" do
      dashboard.archive!

      expect(dashboard.archived?).to be(true)
      expect(dashboard.archived_at).to be_present
      expect(described_class.active).not_to include(dashboard)
      expect(described_class.archived).to include(dashboard)

      dashboard.unarchive!

      expect(dashboard.archived?).to be(false)
      expect(dashboard.archived_at).to be_nil
    end
  end
end
