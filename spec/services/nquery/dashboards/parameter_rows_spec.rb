# frozen_string_literal: true

require_relative "../../../rails_helper"

RSpec.describe Nquery::Dashboards::ParameterRows, ".call" do
  subject(:result) { described_class.call(dashboard: dashboard, attributes: attributes) }

  let(:root_collection) { Nquery::Collection.roots.first }
  let(:admin) { Nquery::User.find_by!(email: "admin@nquery.dev") }
  let(:data_source) { Nquery::DataSource.find_by!(key: "main") }
  let(:dashboard) do
    Nquery::Dashboard.create!(
      name: "Parameter rows",
      collection: root_collection,
      creator: admin
    )
  end
  let(:dated) { chart_for("Dated chart", "SELECT {{start_date}} AS start_date") }
  let(:attributes) { permitted_attributes([{ name: "start_date" }]) }

  def chart_for(name, statement)
    chart = Nquery::Chart.create!(
      name: name,
      collection: root_collection,
      creator: admin,
      visualization: { "type" => "table" },
      query: Nquery::Query.create!(
        name: name,
        statement: statement,
        data_source: data_source,
        creator: admin,
        collection: root_collection,
        parameters: [{ "name" => "start_date", "type" => "date", "default" => "2026-08-01" }]
      )
    )
    dashboard.dashboard_cards.create!(chart: chart, pos_x: 0, pos_y: 0, width: 6, height: 4)
    chart
  end

  def permitted_attributes(parameters)
    ActionController::Parameters.new(parameters: parameters).permit(
      parameters: [:name, :type, :default, { chart_ids: [] }]
    )
  end

  context "when a chart query uses the name" do
    before { dated }

    it "copies a blank type from the chart query" do
      row = result[:parameters].first

      expect(row[:type]).to eq("date")
      expect(row[:default]).to eq("2026-08-01")
    end

    context "when the submitted row has no chart ids" do
      it "fills chart ids from charts whose query uses the name" do
        expect(result[:parameters].first[:chart_ids]).to eq([dated.id])
      end
    end

    context "when the submitted row already has chart ids" do
      let(:attributes) { permitted_attributes([{ name: "start_date", chart_ids: [0] }]) }

      it "leaves those chart ids alone" do
        row = result[:parameters].first

        expect(row[:type]).to eq("date")
        expect(row[:chart_ids]).to eq([0])
      end
    end

    context "when the submitted row already has a type and chart ids" do
      let(:attributes) do
        permitted_attributes([{ name: "start_date", type: "string", default: "kept", chart_ids: [0] }])
      end

      it "leaves the row alone" do
        row = result[:parameters].first

        expect(row[:type]).to eq("string")
        expect(row[:default]).to eq("kept")
        expect(row[:chart_ids]).to eq([0])
      end
    end
  end

  context "when there is no dashboard" do
    it "returns the submitted rows unchanged" do
      filled = described_class.call(dashboard: nil, attributes: attributes)

      expect(filled[:parameters].first[:type]).to be_blank
      expect(filled[:parameters].first[:chart_ids]).to be_blank
    end
  end
end
