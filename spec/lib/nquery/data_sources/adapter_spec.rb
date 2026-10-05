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
    expect { adapter.test_connection }.to raise_error(NotImplementedError)
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
    sqlite_config = ActiveRecord::Base.connection_db_config.configuration_hash.merge(adapter: "sqlite3")
    data_source = Nquery::DataSource.new(
      name: "Ephemeral PG",
      adapter: "postgresql"
    )
    data_source.connection_config_hash = sqlite_config.stringify_keys
    data_source.save!(validate: false)

    expect(described_class.new(data_source).tables).not_to be_empty
  end

  describe "#test_connection" do
    it "returns true when a query succeeds" do
      sqlite_config = ActiveRecord::Base.connection_db_config.configuration_hash.merge(adapter: "sqlite3")
      data_source = Nquery::DataSource.new(name: "Probe", adapter: "postgresql")
      data_source.connection_config_hash = sqlite_config.stringify_keys
      data_source.save!(validate: false)

      expect(described_class.new(data_source).test_connection).to be(true)
    end

    it "raises when the database cannot be reached" do
      allow(adapter).to receive(:with_connection).and_raise(StandardError, "connection refused")

      expect { adapter.test_connection }.to raise_error(StandardError, "connection refused")
    end
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

RSpec.describe Nquery::DataSources::RailsAdapter do
  describe "#test_connection" do
    it "returns true against the host application database" do
      data_source = Nquery::DataSource.new(name: "Main", adapter: "rails")

      expect(described_class.new(data_source).test_connection).to be(true)
    end
  end

  describe "#execute_readonly" do
    let(:data_source) { Nquery::DataSource.new(name: "Main", adapter: "rails") }
    let(:adapter) { described_class.new(data_source) }

    def execute_readonly_sql(statement, **)
      executed_sql = nil
      connection = ActiveRecord::Base.connection
      allow(connection).to receive(:exec_query).and_wrap_original do |method, sql, *args, **kwargs|
        executed_sql = sql
        method.call(sql, *args, **kwargs)
      end

      result = adapter.execute_readonly(statement, **)
      [executed_sql, result]
    end

    context "when the statement has no limit" do
      it "appends the default row cap on the next line and returns rows" do
        sql, result = execute_readonly_sql("SELECT 1 AS value")

        expect(sql).to eq("SELECT 1 AS value\nLIMIT 10000")
        expect(result[:columns]).to include("value")
        expect(result[:row_count]).to eq(1)
      end

      it "strips a trailing semicolon" do
        sql, = execute_readonly_sql("SELECT 1 AS value;")

        expect(sql).to eq("SELECT 1 AS value\nLIMIT 10000")
      end

      it "bounds the row count to an explicit row limit" do
        statement = "SELECT 1 AS value UNION ALL SELECT 2 UNION ALL SELECT 3"
        _sql, result = execute_readonly_sql(statement, row_limit: 2)

        expect(result[:row_count]).to eq(2)
      end

      it "appends the cap on the next line after a trailing comment" do
        statement = "SELECT 1 AS value UNION ALL SELECT 2 UNION ALL SELECT 3 -- all"
        sql, result = execute_readonly_sql(statement, row_limit: 2)

        expect(sql).to eq("#{statement}\nLIMIT 2")
        expect(result[:row_count]).to eq(2)
      end

      it "appends the cap when a limit sits only inside a trailing comment" do
        statement = "SELECT 1 UNION ALL SELECT 2 -- LIMIT 5"
        sql, result = execute_readonly_sql(statement, row_limit: 2)

        expect(sql).to eq("#{statement}\nLIMIT 2")
        expect(result[:row_count]).to eq(2)
      end
    end

    context "when the statement already ends with a limit" do
      it "leaves a smaller limit unchanged" do
        sql, result = execute_readonly_sql("SELECT 1 AS value LIMIT 15")

        expect(sql).to eq("SELECT 1 AS value LIMIT 15")
        expect(result[:columns]).to include("value")
        expect(result[:row_count]).to eq(1)
      end

      it "leaves a trailing offset unchanged" do
        sql, result = execute_readonly_sql("SELECT 1 AS value LIMIT 1 OFFSET 0")

        expect(sql).to eq("SELECT 1 AS value LIMIT 1 OFFSET 0")
        expect(result[:row_count]).to eq(1)
      end

      it "leaves a MySQL-style offset and count unchanged" do
        sql, result = execute_readonly_sql("SELECT 1 AS value LIMIT 0, 1")

        expect(sql).to eq("SELECT 1 AS value LIMIT 0, 1")
        expect(result[:row_count]).to eq(1)
      end

      it "strips a trailing semicolon" do
        sql, result = execute_readonly_sql("SELECT 1 AS value LIMIT 1;")

        expect(sql).to eq("SELECT 1 AS value LIMIT 1")
        expect(result[:row_count]).to eq(1)
      end

      it "leaves a trailing line comment unchanged" do
        sql, result = execute_readonly_sql("SELECT 1 AS value LIMIT 1 -- keep")

        expect(sql).to eq("SELECT 1 AS value LIMIT 1 -- keep")
        expect(result[:row_count]).to eq(1)
      end

      it "rewrites a larger limit in place" do
        statement = "SELECT 1 AS value UNION ALL SELECT 2 UNION ALL SELECT 3 LIMIT 100"
        sql, result = execute_readonly_sql(statement, row_limit: 2)

        expect(sql).to eq("SELECT 1 AS value UNION ALL SELECT 2 UNION ALL SELECT 3 LIMIT 2")
        expect(result[:row_count]).to eq(2)
      end

      it "rewrites a larger limit and keeps the offset" do
        statement = "SELECT 1 AS value UNION ALL SELECT 2 UNION ALL SELECT 3 LIMIT 100 OFFSET 0"
        sql, result = execute_readonly_sql(statement, row_limit: 2)

        expect(sql).to eq("SELECT 1 AS value UNION ALL SELECT 2 UNION ALL SELECT 3 LIMIT 2 OFFSET 0")
        expect(result[:row_count]).to eq(2)
      end

      it "rewrites a larger MySQL count in place" do
        statement = "SELECT 1 AS value UNION ALL SELECT 2 UNION ALL SELECT 3 LIMIT 0, 100"
        sql, result = execute_readonly_sql(statement, row_limit: 2)

        expect(sql).to eq("SELECT 1 AS value UNION ALL SELECT 2 UNION ALL SELECT 3 LIMIT 0, 2")
        expect(result[:row_count]).to eq(2)
      end

      it "leaves a smaller limit unchanged when the line has a quoted double dash" do
        sql, result = execute_readonly_sql("SELECT 'a--b' AS note LIMIT 50")

        expect(sql).to eq("SELECT 'a--b' AS note LIMIT 50")
        expect(result[:row_count]).to eq(1)
      end

      it "rewrites a larger limit in place when the line has a quoted double dash" do
        sql, result = execute_readonly_sql("SELECT 'a--b' AS note LIMIT 50000", row_limit: 2)

        expect(sql).to eq("SELECT 'a--b' AS note LIMIT 2")
        expect(sql.scan(/LIMIT/i).size).to eq(1)
        expect(result[:row_count]).to eq(1)
      end

      it "leaves a smaller limit unchanged when a double dash is inside a block comment" do
        sql, result = execute_readonly_sql("SELECT 1 /* -- note */ LIMIT 50")

        expect(sql).to eq("SELECT 1 /* -- note */ LIMIT 50")
        expect(result[:row_count]).to eq(1)
      end
    end
  end
end
