# frozen_string_literal: true

require "rails_helper"

RSpec.describe Nquery::ChartsHelper, type: :helper do
  include Nquery::Engine.routes.url_helpers

  before do
    helper.extend Nquery::Engine.routes.url_helpers
  end

  describe "#chart_builder_data" do
    it "includes engine query run and schema URLs" do
      data = helper.chart_builder_data(Nquery::Chart.new)

      expect(data[:controller]).to eq("chart-builder")
      expect(data[:query_run_url]).to eq(run_queries_path)
      expect(data[:query_schema_url]).to eq(schema_queries_path)
    end

    context "when the query is persisted" do
      it "includes the query save URL" do
        query = instance_double(Nquery::Query, persisted?: true, to_param: "42")
        chart = instance_double(Nquery::Chart, query: query)

        expect(helper.chart_builder_data(chart)[:query_save_url]).to eq(query_path(query))
      end
    end

    context "when the query is new" do
      it "omits the query save URL" do
        expect(helper.chart_builder_data(Nquery::Chart.new)[:query_save_url]).to be_nil
      end
    end

    context "when a result is passed" do
      it "includes the initial result" do
        result = { "columns" => ["value"] }

        expect(helper.chart_builder_data(Nquery::Chart.new, result: result)[:initial_result]).to eq(result)
      end
    end

    context "without a result" do
      it "omits the initial result" do
        expect(helper.chart_builder_data(Nquery::Chart.new)).not_to have_key(:initial_result)
      end
    end
  end
end
