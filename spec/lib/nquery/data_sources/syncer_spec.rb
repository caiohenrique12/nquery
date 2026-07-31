# frozen_string_literal: true

require_relative "../../../rails_helper"

RSpec.describe Nquery::DataSources::Syncer do
  before do
    Nquery.reset_configuration!
    Nquery.configure do |config|
      config.data_sources = {
        main: { adapter: :rails, name: "Application database" },
        warehouse: { adapter: :postgresql, name: "Warehouse", host: "secret.example.com", password: "secret" }
      }
      config.default_data_source = :main
    end
  end

  describe ".call" do
    it "syncs configured data sources by key" do
      described_class.call

      main = Nquery::DataSource.find_by!(key: "main")
      expect(main.name).to eq("Application database")
      expect(main.adapter).to eq("rails")
      expect(main.connection_config_hash).to eq({})
    end

    it "does not persist credentials from config" do
      described_class.call

      warehouse = Nquery::DataSource.find_by!(key: "warehouse")
      expect(warehouse.connection_config_hash).not_to include("host", "password")
    end

    it "is idempotent" do
      described_class.call

      expect { described_class.call }.not_to change(Nquery::DataSource, :count)
    end

    it "accepts a shorthand adapter definition" do
      Nquery.configure do |config|
        config.data_sources = { analytics: :rails }
        config.default_data_source = :analytics
      end

      described_class.call

      source = Nquery::DataSource.find_by!(key: "analytics")
      expect(source.adapter).to eq("rails")
      expect(source.name).to eq("Analytics")
    end
  end
end
