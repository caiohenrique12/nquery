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

  it "skips audit records when audit is disabled" do
    runner = described_class.new(data_source: data_source, statement: "SELECT 1 AS value", user: user)

    expect {
      runner.run(audit: false)
    }.not_to change(Nquery::Audit, :count)
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
