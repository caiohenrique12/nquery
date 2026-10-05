# frozen_string_literal: true

require "nquery"
require "spec_helper"

RSpec.describe Nquery::QueryRunner do
  let(:data_source) { Nquery::DataSource.create!(name: "Main", adapter: "rails") }
  let(:admin_group) { Nquery::Group.create!(name: "Administrators", system_group: "administrators") }
  let(:user) do
    Nquery::User.create!(email: "runner@example.com", password: "password123").tap do |u|
      Nquery::GroupMembership.create!(user: u, group: admin_group)
    end
  end

  it "rejects blank statements" do
    runner = described_class.new(data_source: data_source, statement: "   ", user: user)
    expect { runner.run }.to raise_error(Nquery::QueryRunner::Error, /blank/i)
  end

  %w[INSERT UPDATE DELETE DROP ALTER CREATE TRUNCATE MERGE REPLACE].each do |keyword|
    it "rejects #{keyword} statements at execution time" do
      statement = case keyword
                  when "INSERT" then "INSERT INTO users (email) VALUES ('x@example.com')"
                  when "UPDATE" then "UPDATE users SET email = 'x@example.com'"
                  when "DELETE" then "DELETE FROM users"
                  when "DROP" then "DROP TABLE users"
                  when "ALTER" then "ALTER TABLE users ADD COLUMN x text"
                  when "CREATE" then "CREATE TABLE evil (id integer)"
                  when "TRUNCATE" then "TRUNCATE TABLE users"
                  when "MERGE" then "MERGE INTO users USING t ON users.id = t.id WHEN MATCHED THEN UPDATE SET email = t.email"
                  when "REPLACE" then "REPLACE INTO users (id, email) VALUES (1, 'x@example.com')"
                  end

      runner = described_class.new(data_source: data_source, statement: statement, user: user)
      expect { runner.run }.to raise_error(Nquery::QueryRunner::Error, /SELECT|read-only|not allowed/i)
    end
  end

  it "rejects forbidden keywords inside CTEs" do
    runner = described_class.new(
      data_source: data_source,
      statement: "WITH x AS (DELETE FROM t RETURNING *) SELECT * FROM x",
      user: user
    )
    expect { runner.run }.to raise_error(Nquery::QueryRunner::Error, /SELECT|read-only|not allowed/i)
  end

  it "rejects multi-statement queries" do
    runner = described_class.new(
      data_source: data_source,
      statement: "SELECT 1; DROP TABLE users",
      user: user
    )
    expect { runner.run }.to raise_error(Nquery::QueryRunner::Error, /Multi-statement/)
  end

  it "rejects SELECT INTO statements" do
    runner = described_class.new(
      data_source: data_source,
      statement: "SELECT * INTO backup FROM users",
      user: user
    )
    expect { runner.run }.to raise_error(Nquery::QueryRunner::Error, /SELECT|read-only|not allowed/i)
  end

  it "runs valid select queries" do
    runner = described_class.new(data_source: data_source, statement: "SELECT 1 AS value", user: user)
    result = runner.run
    expect(result[:columns]).to include("value")
    expect(result[:row_count]).to eq(1)
  end

  it "binds each date placeholder without interpolating the value" do
    date = Date.new(2026, 8, 1)
    executed = capture_exec_query do
      runner = described_class.new(
        data_source: data_source,
        statement: "SELECT 1 AS value WHERE {{start_date}} = {{start_date}}",
        user: user,
        parameters: { "start_date" => date }
      )

      expect(runner.run(audit: false)[:row_count]).to eq(1)
    end

    expect(executed[:sql]).to include("?")
    expect(executed[:sql]).not_to include("2026-08-01")
    expect(executed[:sql]).not_to include("OR")
    expect(executed[:args].last.size).to eq(2)
  end

  it "executes a statement without placeholders and without binds" do
    executed = capture_exec_query do
      runner = described_class.new(
        data_source: data_source,
        statement: "SELECT 1 AS value",
        user: user,
        parameters: { "start_date" => Date.new(2026, 8, 1) }
      )
      runner.run(audit: false)
    end

    expect(executed[:sql]).to include("SELECT 1 AS value")
    expect(executed[:sql]).not_to include("{{")
    expect(executed[:args]).to be_empty
  end

  it "does not execute when a placeholder is unknown" do
    expect(Nquery::DataSources::Adapter).not_to receive(:for)

    runner = described_class.new(
      data_source: data_source,
      statement: "SELECT {{other}}",
      user: user,
      parameters: { "start_date" => Date.new(2026, 8, 1) }
    )

    expect { runner.run }.to raise_error(described_class::ParameterError, "Unknown parameter other")
  end

  it "does not execute when a placeholder is left open" do
    expect(Nquery::DataSources::Adapter).not_to receive(:for)

    runner = described_class.new(
      data_source: data_source,
      statement: "SELECT 1 WHERE created_at >= {{start_date",
      user: user,
      parameters: { "start_date" => Date.new(2026, 8, 1) }
    )

    expect { runner.run }.to raise_error(described_class::ParameterError, "Invalid parameter placeholder")
  end

  it "does not execute when a value is missing" do
    expect(Nquery::DataSources::Adapter).not_to receive(:for)

    runner = described_class.new(
      data_source: data_source,
      statement: "SELECT 1 WHERE {{start_date}} = 1",
      user: user,
      parameters: { "start_date" => nil }
    )

    expect { runner.run }.to raise_error(described_class::ParameterError, "Missing value for start_date")
  end

  it "does not execute when a value is not a date" do
    raw = "2026-08-01'; DROP TABLE nquery_users"
    expect(Nquery::DataSources::Adapter).not_to receive(:for)

    runner = described_class.new(
      data_source: data_source,
      statement: "SELECT 1 WHERE {{start_date}} = 1",
      user: user,
      parameters: { "start_date" => raw }
    )

    expect { runner.run }.to raise_error(described_class::ParameterError, "Invalid value for start_date") { |error|
      expect(error.message).not_to include(raw)
    }
  end

  it "rejects non-select statements before binding placeholders" do
    expect(Nquery::DataSources::Adapter).not_to receive(:for)

    runner = described_class.new(
      data_source: data_source,
      statement: "DELETE FROM users WHERE id = {{start_date}}",
      user: user,
      parameters: { "start_date" => Date.new(2026, 8, 1) }
    )

    expect { runner.run }.to raise_error(described_class::Error, /SELECT|read-only|not allowed/i)
  end

  context "when the statement already has a limit" do
    it "caps rows at the configured query row limit" do
      previous_limit = Nquery.configuration.query_row_limit
      Nquery.configuration.query_row_limit = 2
      statement = "SELECT 1 AS value UNION ALL SELECT 2 UNION ALL SELECT 3 LIMIT 100"
      runner = described_class.new(data_source: data_source, statement: statement, user: user)

      expect(runner.run[:row_count]).to eq(2)
    ensure
      Nquery.configuration.query_row_limit = previous_limit
    end
  end

  it "skips audit records when audit is disabled" do
    runner = described_class.new(data_source: data_source, statement: "SELECT 1 AS value", user: user)

    expect {
      runner.run(audit: false)
    }.not_to change(Nquery::Audit, :count)
  end

  def capture_exec_query
    executed = nil
    connection = ActiveRecord::Base.connection
    allow(connection).to receive(:exec_query).and_wrap_original do |method, sql, *args, **kwargs|
      executed = { sql: sql, args: args, kwargs: kwargs }
      method.call(sql, *args, **kwargs)
    end
    yield
    executed
  end

  it "re-raises permission errors without wrapping" do
    viewer_group = Nquery::Group.create!(name: "Blocked", system_group: "custom")
    viewer = Nquery::User.create!(email: "blocked@example.com", password: "password123").tap do |u|
      Nquery::GroupMembership.create!(user: u, group: viewer_group)
    end
    Nquery::DataPermission.create!(
      group: viewer_group,
      data_source: data_source,
      permission_type: "view_data",
      access_level: "blocked"
    )

    runner = described_class.new(data_source: data_source, statement: "SELECT 1 AS value", user: viewer)

    expect { runner.run }.to raise_error(described_class::PermissionError)
    expect(Nquery::Audit.where(status: "error")).to be_empty
  end
end
