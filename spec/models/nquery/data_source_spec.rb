# frozen_string_literal: true

require_relative "../../rails_helper"

RSpec.describe Nquery::DataSource do
  describe "encryption" do
    it "encrypts connection_config at rest" do
      data_source = described_class.create!(
        name: "Encrypted Warehouse",
        adapter: "postgresql",
        connection_fields_submitted: true,
        host: "db.example.com",
        database: "warehouse",
        username: "reader",
        password: "secret-pass"
      )

      raw = ActiveRecord::Base.connection.select_value(
        ActiveRecord::Base.sanitize_sql_array(
          ["SELECT connection_config FROM nquery_data_sources WHERE id = ?", data_source.id]
        )
      )

      expect(raw).to be_present
      expect(raw).not_to include("secret-pass")
      expect(data_source.reload.connection_config_hash).to include(
        "host" => "db.example.com",
        "database" => "warehouse",
        "username" => "reader",
        "password" => "secret-pass",
        "adapter" => "postgresql"
      )
    end
  end

  describe "#connection_config_hash" do
    it "returns a normalized hash" do
      data_source = described_class.new
      data_source.connection_config_hash = { host: "localhost" }

      expect(data_source.connection_config_hash).to eq("host" => "localhost")
    end

    it "returns an empty hash for blank config" do
      expect(described_class.new(connection_config: nil).connection_config_hash).to eq({})
    end
  end

  describe "connection fields" do
    it "composes postgres config with defaults" do
      data_source = described_class.new(
        name: "Warehouse",
        adapter: "postgresql",
        connection_fields_submitted: true,
        host: "localhost",
        database: "analytics",
        username: "reader",
        password: "secret"
      )
      data_source.valid?

      expect(data_source.connection_config_hash).to include(
        "adapter" => "postgresql",
        "host" => "localhost",
        "port" => 5432,
        "database" => "analytics",
        "username" => "reader",
        "password" => "secret"
      )
    end

    it "maps mysql adapter to mysql2" do
      data_source = described_class.new(
        name: "MySQL",
        adapter: "mysql",
        connection_fields_submitted: true,
        host: "localhost",
        database: "shop",
        username: "root",
        password: "secret"
      )
      data_source.valid?

      expect(data_source.connection_config_hash).to include(
        "adapter" => "mysql2",
        "port" => 3306
      )
    end

    it "composes sqlite config from database path" do
      data_source = described_class.new(
        name: "Local SQLite",
        adapter: "sqlite",
        connection_fields_submitted: true,
        database_path: "/tmp/test.sqlite3"
      )
      data_source.valid?

      expect(data_source.connection_config_hash).to eq(
        "adapter" => "sqlite3",
        "database" => "/tmp/test.sqlite3"
      )
    end

    it "keeps the existing password when edit leaves password blank" do
      data_source = described_class.create!(
        name: "Warehouse",
        adapter: "postgresql",
        connection_fields_submitted: true,
        host: "localhost",
        database: "analytics",
        username: "reader",
        password: "original-secret"
      )

      data_source.assign_attributes(
        connection_fields_submitted: true,
        host: "localhost",
        database: "analytics",
        username: "reader",
        password: ""
      )
      data_source.valid?
      data_source.save!

      expect(data_source.reload.connection_config_hash["password"]).to eq("original-secret")
    end

    it "requires remote credentials on create" do
      data_source = described_class.new(
        name: "Warehouse",
        adapter: "postgresql",
        connection_fields_submitted: true
      )

      expect(data_source).not_to be_valid
      expect(data_source.errors[:host]).to include("can't be blank")
      expect(data_source.errors[:database]).to include("can't be blank")
      expect(data_source.errors[:username]).to include("can't be blank")
      expect(data_source.errors[:password]).to include("can't be blank")
    end

    it "populates virtual fields from stored config" do
      data_source = described_class.create!(
        name: "Warehouse",
        adapter: "postgresql",
        connection_fields_submitted: true,
        host: "db.internal",
        port: "5433",
        database: "warehouse",
        username: "reader",
        password: "secret",
        sslmode: "require"
      )

      data_source.assign_connection_fields_from_config

      expect(data_source.host).to eq("db.internal")
      expect(data_source.port).to eq("5433")
      expect(data_source.database).to eq("warehouse")
      expect(data_source.username).to eq("reader")
      expect(data_source.password).to be_nil
      expect(data_source.sslmode).to eq("require")
    end

    it "clears stored credentials for rails adapter" do
      data_source = described_class.create!(
        name: "Warehouse",
        adapter: "postgresql",
        connection_fields_submitted: true,
        host: "localhost",
        database: "analytics",
        username: "reader",
        password: "secret"
      )

      data_source.assign_attributes(name: "Main Database", adapter: "rails")
      data_source.connection_fields_submitted = false
      data_source.save!

      expect(data_source.reload.connection_config_hash).to eq({})
    end
  end
end
