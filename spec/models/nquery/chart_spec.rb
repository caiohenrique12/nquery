# frozen_string_literal: true

require_relative "../../rails_helper"

RSpec.describe Nquery::Chart do
  let(:admin) { Nquery::User.find_by!(email: "admin@nquery.dev") }
  let(:data_source) { Nquery::DataSource.find_by!(key: "main") }
  let(:root_collection) { Nquery::Collection.roots.first }

  describe "#unarchive!" do
    it "clears archived_at" do
      query = Nquery::Query.create!(
        name: "Archived chart query",
        statement: "SELECT 1",
        data_source: data_source,
        creator: admin,
        collection: root_collection
      )
      chart = described_class.create!(
        name: "Archived chart",
        query: query,
        collection: root_collection,
        creator: admin,
        visualization: { "type" => "bar" },
        archived_at: 1.day.ago
      )

      chart.unarchive!

      expect(chart.archived?).to be(false)
    end
  end

  describe "#chart_type" do
    it "defaults to bar when visualization type is missing" do
      chart = described_class.new(visualization: {})
      expect(chart.chart_type).to eq("bar")
    end
  end
end
