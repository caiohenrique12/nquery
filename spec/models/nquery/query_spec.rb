# frozen_string_literal: true

require "nquery"
require_relative "../../rails_helper"

RSpec.describe Nquery::Query, type: :model do
  let(:data_source) { Nquery::DataSource.create!(name: "Query Spec DB", adapter: "rails") }
  let(:user) { Nquery::User.create!(email: "query-spec@example.com", password: "password123") }

  def build_query(statement:)
    described_class.new(
      name: "Spec query",
      statement: statement,
      data_source: data_source,
      creator: user
    )
  end

  it "allows SELECT statements" do
    query = build_query(statement: "SELECT 1 AS value")

    expect(query).to be_valid
  end

  it "allows WITH (CTE) SELECT statements" do
    query = build_query(statement: "WITH cte AS (SELECT 1 AS value) SELECT * FROM cte")

    expect(query).to be_valid
  end

  it "allows blank statements for drafts" do
    query = build_query(statement: "")

    expect(query).to be_valid
  end

  %w[
    INSERT
    UPDATE
    DELETE
    DROP
    ALTER
    CREATE
    TRUNCATE
    MERGE
    REPLACE
  ].each do |keyword|
    it "rejects #{keyword} statements on create" do
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

      query = build_query(statement: statement)

      expect(query).not_to be_valid
      expect(query.errors[:statement].join).to match(/SELECT|read-only|not allowed/i)
    end
  end

  it "rejects forbidden keywords inside CTEs" do
    query = build_query(statement: "WITH x AS (DELETE FROM t RETURNING *) SELECT * FROM x")

    expect(query).not_to be_valid
    expect(query.errors[:statement].join).to match(/SELECT|read-only|not allowed/i)
  end

  it "rejects multi-statement SQL" do
    query = build_query(statement: "SELECT 1; DELETE FROM users")

    expect(query).not_to be_valid
    expect(query.errors[:statement].join).to match(/multi-statement/i)
  end

  it "rejects SELECT INTO statements" do
    query = build_query(statement: "SELECT * INTO backup FROM users")

    expect(query).not_to be_valid
    expect(query.errors[:statement].join).to match(/SELECT|read-only|not allowed/i)
  end

  it "rejects mutating statements on update" do
    query = build_query(statement: "SELECT 1 AS value")
    query.save!

    query.statement = "DELETE FROM users"

    expect(query).not_to be_valid
    expect(query.errors[:statement].join).to match(/SELECT|read-only|not allowed/i)
  end
end
