# frozen_string_literal: true

require_relative "../../../rails_helper"

RSpec.describe Nquery::Dashboards::Filters, ".call" do
  subject(:result) { described_class.call(dashboard: dashboard, request_params: request_params) }

  let(:root_collection) { Nquery::Collection.roots.first }
  let(:admin) { Nquery::User.find_by!(email: "admin@nquery.dev") }
  let(:dashboard) do
    Nquery::Dashboard.create!(
      name: "Service filters",
      collection: root_collection,
      creator: admin,
      parameters: [
        { "name" => "start_date", "type" => "date", "default" => "2026-08-01" }
      ]
    )
  end
  let(:request_params) { ActionController::Parameters.new }

  it "uses the saved default when the request omits the filter" do
    expect(result.filter_dashboard).to eq(dashboard)
    expect(result.parameters.values["start_date"]).to eq(Date.new(2026, 8, 1))
  end

  it "lets a declared request date override the default" do
    request_params[:start_date] = "2026-01-15"

    expect(result.parameters.values["start_date"]).to eq(Date.new(2026, 1, 15))
  end

  it "ignores a request key the dashboard did not declare" do
    request_params[:evil] = "2026-01-01"

    expect(result.parameters.values.keys).to eq(["start_date"])
    expect(result.parameters.values["start_date"]).to eq(Date.new(2026, 8, 1))
  end

  context "when the submitted date is blank" do
    let(:request_params) { ActionController::Parameters.new(start_date: "") }

    it "skips the saved default" do
      expect(result.parameters.values).not_to have_key("start_date")
    end
  end

  context "when the dashboard has invalid parameter changes" do
    before do
      dashboard.parameters = [{ "name" => "Start Date", "type" => "date", "default" => "2026-02-31" }]
      dashboard.validate
    end

    it "resolves filters from the saved dashboard" do
      expect(dashboard.errors).to be_any
      expect(result.filter_dashboard.parameter_names).to eq(["start_date"])
      expect(result.parameters.values["start_date"]).to eq(Date.new(2026, 8, 1))
    end
  end
end
