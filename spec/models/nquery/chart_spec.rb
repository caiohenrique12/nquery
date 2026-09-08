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

  describe "#statement" do
    it "is nil without a query" do
      expect(described_class.new.statement).to be_nil
    end

    it "returns the query statement" do
      chart = described_class.new(query: Nquery::Query.new(statement: "SELECT 1"))

      expect(chart.statement).to eq("SELECT 1")
    end
  end

  describe "#statement?" do
    it "is false without a query" do
      expect(described_class.new.statement?).to be(false)
    end

    it "is false when the query has a blank statement" do
      chart = described_class.new(query: Nquery::Query.new(statement: ""))

      expect(chart.statement?).to be(false)
    end

    it "is true when the query has a statement" do
      chart = described_class.new(query: Nquery::Query.new(statement: "SELECT 1"))

      expect(chart.statement?).to be(true)
    end
  end

  describe "#data_source" do
    it "is nil without a query" do
      expect(described_class.new.data_source).to be_nil
    end

    it "returns the query data source" do
      chart = described_class.new(query: Nquery::Query.new(data_source: data_source))

      expect(chart.data_source).to eq(data_source)
    end
  end
end
