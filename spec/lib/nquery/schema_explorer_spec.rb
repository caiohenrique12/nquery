# frozen_string_literal: true

require_relative "../../rails_helper"

RSpec.describe Nquery::SchemaExplorer do
  let(:data_source) { Nquery::DataSource.find_by!(key: "main") }

  describe ".tables_for" do
    it "returns tables with column metadata" do
      tables = described_class.tables_for(data_source)

      expect(tables).not_to be_empty
      expect(tables.first).to include(:name, :columns)
      expect(tables.first[:columns].first).to include(:name, :type)
    end

    it "returns an empty array when data source is nil" do
      expect(described_class.tables_for(nil)).to eq([])
    end

    it "returns an empty array and logs when adapter introspection fails" do
      allow(Nquery::DataSources::Adapter).to receive(:for).and_raise(StandardError, "boom")
      expect(Rails.logger).to receive(:error).with(/SchemaExplorer/)

      expect(described_class.tables_for(data_source)).to eq([])
    end
  end
end
