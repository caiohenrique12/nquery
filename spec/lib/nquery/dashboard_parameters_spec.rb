# frozen_string_literal: true

require_relative "../../rails_helper"

RSpec.describe Nquery::DashboardParameters do
  let(:root_collection) { Nquery::Collection.roots.first }
  let(:admin) { Nquery::User.find_by!(email: "admin@nquery.dev") }
  let(:dashboard) do
    Nquery::Dashboard.create!(
      name: "Filtered board",
      collection: root_collection,
      creator: admin,
      parameters: [
        { "name" => "start_date", "type" => "date", "default" => "2026-08-01" },
        { "name" => "end_date", "type" => "date", "default" => "2026-08-07" },
        { "name" => "as_of", "type" => "date", "default" => "" }
      ]
    )
  end

  def resolve(token_params: {}, request_params: {})
    described_class.call(dashboard: dashboard, token_params: token_params, request_params: request_params)
  end

  it "uses the default when both sources omit the name" do
    result = resolve

    expect(result.values).to include(
      "start_date" => Date.new(2026, 8, 1),
      "end_date" => Date.new(2026, 8, 7)
    )
    expect(result.values).not_to have_key("as_of")
    expect(result.invalid_names).to be_empty
    expect(result.values.values).to all(be_a(Date))
  end

  it "lets token params override the default" do
    result = resolve(token_params: { "start_date" => "2026-01-01" })

    expect(result.values["start_date"]).to eq(Date.new(2026, 1, 1))
    expect(result.values["end_date"]).to eq(Date.new(2026, 8, 7))
  end

  it "keeps a token value when the query string disagrees" do
    result = resolve(
      token_params: { "start_date" => "2026-01-01", "end_date" => "2026-01-15" },
      request_params: { "start_date" => "2026-03-01" }
    )

    expect(result.values["start_date"]).to eq(Date.new(2026, 1, 1))
    expect(result.values["end_date"]).to eq(Date.new(2026, 1, 15))
  end

  it "lets the query string set a parameter the token omits" do
    result = resolve(
      token_params: { "end_date" => "2026-01-15" },
      request_params: { "start_date" => "2026-03-01" }
    )

    expect(result.values["start_date"]).to eq(Date.new(2026, 3, 1))
    expect(result.values["end_date"]).to eq(Date.new(2026, 1, 15))
  end

  it "marks a present invalid date and does not fall through" do
    result = resolve(request_params: { "start_date" => "2026-02-31" })

    expect(result.values).not_to have_key("start_date")
    expect(result.invalid_names).to eq(["start_date"])
    expect(result.values["end_date"]).to eq(Date.new(2026, 8, 7))
  end

  it "keeps the token date when the query string is invalid" do
    result = resolve(
      token_params: { "start_date" => "2026-01-01" },
      request_params: { "start_date" => "2026-02-31" }
    )

    expect(result.values["start_date"]).to eq(Date.new(2026, 1, 1))
    expect(result.invalid_names).to be_empty
  end

  it "does not fall through when the query string is an injection attempt" do
    raw = "2026-08-01' OR '1'='1"
    result = resolve(request_params: { "start_date" => raw })

    expect(result.values).not_to have_key("start_date")
    expect(result.invalid_names).to eq(["start_date"])
    expect(result.values.values).to all(be_a(Date))
  end

  it "keeps the token date when the query string is an injection attempt" do
    raw = "2026-08-01' OR '1'='1"
    result = resolve(
      token_params: { "start_date" => "2026-01-01" },
      request_params: { "start_date" => raw }
    )

    expect(result.values["start_date"]).to eq(Date.new(2026, 1, 1))
    expect(result.invalid_names).to be_empty
  end

  it "treats a blank value as omitted" do
    result = resolve(
      token_params: { "start_date" => "2026-01-01" },
      request_params: { "start_date" => "  " }
    )

    expect(result.values["start_date"]).to eq(Date.new(2026, 1, 1))
    expect(result.invalid_names).to be_empty
  end

  it "drops keys that are not declared" do
    result = resolve(
      token_params: { "theme" => "night", "evil" => "1", "start_date" => "2026-04-01" },
      request_params: { "titled" => "false", "bordered" => "false", "token" => "abc", "evil" => "x" }
    )

    expect(result.values.keys).to eq(%w[start_date end_date])
    expect(result.values["start_date"]).to eq(Date.new(2026, 4, 1))
    expect(result.invalid_names).to be_empty
  end

  context "with string, integer, and datetime parameters" do
    let(:dashboard) do
      Nquery::Dashboard.create!(
        name: "Typed board",
        collection: root_collection,
        creator: admin,
        parameters: [
          { "name" => "region", "type" => "string", "default" => "north" },
          { "name" => "minimum", "type" => "integer", "default" => "3" },
          { "name" => "as_of", "type" => "datetime", "default" => "2026-08-01T15:30" }
        ]
      )
    end

    it "parses each default into a bindable value" do
      result = resolve

      expect(result.values["region"]).to eq("north")
      expect(result.values["minimum"]).to eq(3)
      expect(result.values["as_of"]).to eq(Time.zone.parse("2026-08-01T15:30"))
      expect(result.invalid_names).to be_empty
    end

    it "marks an invalid integer and does not fall through to the default" do
      result = resolve(request_params: { "minimum" => "3; DROP TABLE nquery_users" })

      expect(result.values).not_to have_key("minimum")
      expect(result.invalid_names).to eq(["minimum"])
    end
  end

  context "with a boolean parameter" do
    let(:dashboard) do
      Nquery::Dashboard.create!(
        name: "Boolean board",
        collection: root_collection,
        creator: admin,
        parameters: [
          { "name" => "active", "type" => "boolean", "default" => "false" }
        ]
      )
    end

    it "uses a false default" do
      result = resolve

      expect(result.values["active"]).to be(false)
      expect(result.invalid_names).to be_empty
    end

    it "parses yes as true" do
      result = resolve(request_params: { "active" => "yes" })

      expect(result.values["active"]).to be(true)
    end

    it "marks an invalid boolean and does not fall through to the default" do
      result = resolve(request_params: { "active" => "maybe" })

      expect(result.values).not_to have_key("active")
      expect(result.invalid_names).to eq(["active"])
    end
  end

  context "with a uuid parameter" do
    let(:dashboard) do
      Nquery::Dashboard.create!(
        name: "Uuid board",
        collection: root_collection,
        creator: admin,
        parameters: [
          { "name" => "customer_id", "type" => "uuid", "default" => "550e8400-e29b-41d4-a716-446655440000" }
        ]
      )
    end

    it "parses the default into a lowercase uuid" do
      result = resolve

      expect(result.values["customer_id"]).to eq("550e8400-e29b-41d4-a716-446655440000")
      expect(result.invalid_names).to be_empty
    end

    it "marks an invalid uuid and does not fall through to the default" do
      result = resolve(request_params: { "customer_id" => "550e8400-e29b-41d4-a716-446655440000' OR '1'='1" })

      expect(result.values).not_to have_key("customer_id")
      expect(result.invalid_names).to eq(["customer_id"])
    end
  end
end
