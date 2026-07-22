# frozen_string_literal: true

require_relative "../../rails_helper"

RSpec.describe Nquery::DataSource do
  describe "#connection_config_hash" do
    it "returns parsed JSON" do
      data_source = described_class.new(connection_config: '{"host":"localhost"}')
      expect(data_source.connection_config_hash).to eq("host" => "localhost")
    end

    it "returns an empty hash for blank config" do
      expect(described_class.new(connection_config: "").connection_config_hash).to eq({})
    end

    it "returns an empty hash for invalid JSON" do
      expect(described_class.new(connection_config: "not-json").connection_config_hash).to eq({})
    end
  end

  describe "#connection_config_hash=" do
    it "serializes to JSON" do
      data_source = described_class.new
      data_source.connection_config_hash = { database: "mydb" }
      expect(data_source.connection_config).to eq('{"database":"mydb"}')
    end
  end
end
