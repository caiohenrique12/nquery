# frozen_string_literal: true

require_relative "../../rails_helper"

RSpec.describe Nquery::SchemaExplorer do
  let(:data_source) { Nquery::DataSource.find_by!(name: "Main Database") }

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
  end
end
