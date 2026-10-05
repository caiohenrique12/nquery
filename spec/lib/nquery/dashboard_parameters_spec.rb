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

  it "lets the query string override the token" do
    result = resolve(
      token_params: { "start_date" => "2026-01-01", "end_date" => "2026-01-15" },
      request_params: { "start_date" => "2026-03-01" }
    )

    expect(result.values["start_date"]).to eq(Date.new(2026, 3, 1))
    expect(result.values["end_date"]).to eq(Date.new(2026, 1, 15))
  end

  it "marks a present invalid date and does not fall through" do
    result = resolve(
      token_params: { "start_date" => "2026-01-01" },
      request_params: { "start_date" => "2026-02-31" }
    )

    expect(result.values).not_to have_key("start_date")
    expect(result.invalid_names).to eq(["start_date"])
    expect(result.values["end_date"]).to eq(Date.new(2026, 8, 7))
  end

  it "does not fall through when the query string is an injection attempt" do
    raw = "2026-08-01' OR '1'='1"
    result = resolve(
      token_params: { "start_date" => "2026-01-01" },
      request_params: { "start_date" => raw }
    )

    expect(result.values).not_to have_key("start_date")
    expect(result.invalid_names).to eq(["start_date"])
    expect(result.values.values).to all(be_a(Date))
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
end
