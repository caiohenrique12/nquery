# frozen_string_literal: true

require_relative "../../../rails_helper"

RSpec.describe Nquery::Dashboards::CardParameters, ".call" do
  subject(:result) { described_class.call(dashboard: dashboard, chart: dated, linked_names: linked_names) }

  let(:root_collection) { Nquery::Collection.roots.first }
  let(:admin) { Nquery::User.find_by!(email: "admin@nquery.dev") }
  let(:data_source) { Nquery::DataSource.find_by!(key: "main") }
  let(:dashboard) do
    Nquery::Dashboard.create!(
      name: "Card links",
      collection: root_collection,
      creator: admin,
      parameters: [{ "name" => "start_date", "type" => "date", "default" => "2026-08-01" }]
    )
  end
  let(:dated) { chart_for("Dated card", "SELECT {{start_date}} AS start_date") }
  let(:plain) { chart_for("Plain card", "SELECT 'plain' AS label") }
  let(:linked_names) { [] }

  def chart_for(name, statement)
    Nquery::Chart.create!(
      name: name,
      collection: root_collection,
      creator: admin,
      visualization: { "type" => "table" },
      query: Nquery::Query.create!(
        name: name,
        statement: statement,
        data_source: data_source,
        creator: admin,
        collection: root_collection
      )
    )
  end

  before do
    dashboard.dashboard_cards.create!(chart: dated, pos_x: 0, pos_y: 0, width: 6, height: 4)
    dashboard.dashboard_cards.create!(chart: plain, pos_x: 6, pos_y: 0, width: 6, height: 4)
  end

  it "does not keep charts whose query omits the variable" do
    expect(result.parameter_definitions.first["chart_ids"]).to eq([])
  end

  context "when the chart stays linked" do
    let(:linked_names) { ["start_date"] }

    it "records only that chart" do
      expect(result.parameter_definitions.first["chart_ids"]).to eq([dated.id])
    end
  end
end
