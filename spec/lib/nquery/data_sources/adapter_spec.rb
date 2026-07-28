# frozen_string_literal: true

require_relative "../../../rails_helper"

RSpec.describe Nquery::DataSources::Adapter do
  it "returns the correct adapter class" do
    rails = Nquery::DataSource.new(adapter: "rails")
    postgres = Nquery::DataSource.new(adapter: "postgresql")
    mysql = Nquery::DataSource.new(adapter: "mysql")
    sqlite = Nquery::DataSource.new(adapter: "sqlite")

    expect(described_class.for(rails)).to be_a(Nquery::DataSources::RailsAdapter)
    expect(described_class.for(postgres)).to be_a(Nquery::DataSources::PostgresqlAdapter)
    expect(described_class.for(mysql)).to be_a(Nquery::DataSources::MysqlAdapter)
    expect(described_class.for(sqlite)).to be_a(Nquery::DataSources::SqliteAdapter)
  end

  it "raises for unknown adapters" do
    data_source = Nquery::DataSource.new(adapter: "unknown")

    expect { described_class.for(data_source) }.to raise_error(ArgumentError, /Unknown adapter/)
  end

  it "raises NotImplementedError for base methods" do
    adapter = described_class.new(Nquery::DataSource.new(adapter: "rails"))

    expect { adapter.tables }.to raise_error(NotImplementedError)
    expect { adapter.columns("users") }.to raise_error(NotImplementedError)
    expect { adapter.execute_readonly("SELECT 1") }.to raise_error(NotImplementedError)
  end
end

RSpec.describe Nquery::DataSources::PostgresqlAdapter do
  let(:data_source) do
    Nquery::DataSource.new(adapter: "postgresql", connection_config_hash: { "adapter" => "postgresql" })
  end
  let(:adapter) { described_class.new(data_source) }
  let(:connection) do
    double(
      "connection",
      tables: ["users"],
      columns: [double(name: "id", type: :integer)],
      transaction: nil,
      execute: nil,
      exec_query: double(columns: %w[id], rows: [[1]])
    )
  end

  before do
    allow(adapter).to receive(:with_connection).and_yield(connection)
    allow(connection).to receive(:transaction) do |&block|
      block.call
    rescue ActiveRecord::Rollback
    end
  end

  it "lists tables and columns" do
    expect(adapter.tables).to eq(["users"])
    expect(adapter.columns("users")).to eq([{ name: "id", type: "integer" }])
  end

  it "executes read-only queries" do
    result = adapter.execute_readonly("SELECT 1 AS id;")

    expect(result[:columns]).to eq(%w[id])
    expect(result[:rows]).to eq([[1]])
    expect(result[:row_count]).to eq(1)
    expect(result[:duration_ms]).to be_a(Integer)
  end

  it "opens and closes ephemeral connections" do
    connection_class = Class.new(ActiveRecord::Base) do
      self.abstract_class = true

      def self.name
        "Nquery::EphemeralConnection"
      end
    end
    allow(Class).to receive(:new).with(ActiveRecord::Base).and_return(connection_class)

    sqlite_config = ActiveRecord::Base.connection_db_config.configuration_hash.merge(adapter: "sqlite3")
    data_source = Nquery::DataSource.new(
      name: "Ephemeral PG",
      adapter: "postgresql"
    )
    data_source.connection_config_hash = sqlite_config.stringify_keys
    data_source.save!(validate: false)

    expect(described_class.new(data_source).tables).not_to be_empty
  end
end

RSpec.describe Nquery::DataSources::MysqlAdapter do
  let(:data_source) do
    Nquery::DataSource.new(adapter: "mysql", connection_config_hash: { "adapter" => "mysql2" })
  end
  let(:adapter) { described_class.new(data_source) }
  let(:connection) do
    double(
      "connection",
      transaction: nil,
      execute: nil,
      exec_query: double(columns: %w[value], rows: [[1]])
    )
  end

  before do
    allow(adapter).to receive(:with_connection).and_yield(connection)
    allow(connection).to receive(:transaction) do |&block|
      block.call
    rescue ActiveRecord::Rollback
    end
  end

  it "executes read-only queries with a MySQL session" do
    expect(connection).to receive(:execute).with("SET SESSION TRANSACTION READ ONLY")

    result = adapter.execute_readonly("SELECT 1 AS value")

    expect(result[:columns]).to eq(%w[value])
    expect(result[:rows]).to eq([[1]])
  end
end
