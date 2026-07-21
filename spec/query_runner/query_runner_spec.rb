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

  it "rejects non-select statements" do
    runner = described_class.new(data_source: data_source, statement: "DELETE FROM users", user: user)
    expect { runner.run }.to raise_error(Nquery::QueryRunner::Error, /SELECT/)
  end

  it "rejects forbidden keywords inside CTEs" do
    runner = described_class.new(
      data_source: data_source,
      statement: "WITH x AS (DELETE FROM t RETURNING *) SELECT * FROM x",
      user: user
    )
    expect { runner.run }.to raise_error(Nquery::QueryRunner::Error, /SELECT/)
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
    expect { runner.run }.to raise_error(Nquery::QueryRunner::Error, /SELECT/)
  end

  it "runs valid select queries" do
    runner = described_class.new(data_source: data_source, statement: "SELECT 1 AS value", user: user)
    result = runner.run
    expect(result[:columns]).to include("value")
    expect(result[:row_count]).to eq(1)
  end
end
