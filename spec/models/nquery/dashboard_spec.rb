# frozen_string_literal: true

require_relative "../../rails_helper"

RSpec.describe Nquery::Dashboard do
  let(:root_collection) { Nquery::Collection.roots.first }
  let(:admin) { Nquery::User.find_by!(email: "admin@nquery.dev") }

  describe "validations" do
    it "requires a collection" do
      dashboard = described_class.new(name: "Ops overview", creator: admin)

      expect(dashboard).not_to be_valid
      expect(dashboard.errors[:collection]).to include("must exist")
    end

    it "is valid with a collection" do
      dashboard = described_class.new(
        name: "Ops overview",
        collection: root_collection,
        creator: admin
      )

      expect(dashboard).to be_valid
    end
  end

  describe "parameters" do
    def build_dashboard(parameters:)
      described_class.new(
        name: "Ops overview",
        collection: root_collection,
        creator: admin,
        parameters: parameters
      )
    end

    it "accepts a date parameter with a default" do
      dashboard = build_dashboard(
        parameters: [{ "name" => "start_date", "type" => "date", "default" => "2026-08-01" }]
      )

      expect(dashboard).to be_valid
      dashboard.save!

      expect(dashboard.parameter_definitions).to eq(
        [{ "name" => "start_date", "type" => "date", "default" => "2026-08-01" }]
      )
      expect(dashboard.parameter_names).to eq(["start_date"])
    end

    it "accepts a blank default" do
      dashboard = build_dashboard(
        parameters: [{ "name" => "start_date", "type" => "date", "default" => "" }]
      )

      expect(dashboard).to be_valid
    end

    it "drops rows whose name is blank" do
      dashboard = build_dashboard(
        parameters: [
          { "name" => "  ", "type" => "date", "default" => "2026-08-01" },
          { "name" => "end_date", "type" => "date", "default" => "" }
        ]
      )

      expect(dashboard).to be_valid
      dashboard.save!

      expect(dashboard.parameter_names).to eq(["end_date"])
    end

    it "rejects a name that is not a lowercase identifier" do
      dashboard = build_dashboard(
        parameters: [{ "name" => "Start-Date", "type" => "date", "default" => "" }]
      )

      expect(dashboard).not_to be_valid
      expect(dashboard.errors[:parameters]).to be_present
    end

    it "rejects a duplicate name" do
      dashboard = build_dashboard(
        parameters: [
          { "name" => "start_date", "type" => "date", "default" => "" },
          { "name" => "start_date", "type" => "date", "default" => "2026-08-01" }
        ]
      )

      expect(dashboard).not_to be_valid
      expect(dashboard.errors[:parameters]).to be_present
    end

    %w[token titled bordered theme].each do |reserved|
      it "rejects the reserved name #{reserved}" do
        dashboard = build_dashboard(
          parameters: [{ "name" => reserved, "type" => "date", "default" => "" }]
        )

        expect(dashboard).not_to be_valid
        expect(dashboard.errors[:parameters]).to be_present
      end
    end

    it "rejects a type other than date" do
      dashboard = build_dashboard(
        parameters: [{ "name" => "start_date", "type" => "string", "default" => "" }]
      )

      expect(dashboard).not_to be_valid
      expect(dashboard.errors[:parameters]).to be_present
    end

    it "rejects a default that is not a real calendar date" do
      dashboard = build_dashboard(
        parameters: [{ "name" => "start_date", "type" => "date", "default" => "2026-02-31" }]
      )

      expect(dashboard).not_to be_valid
      expect(dashboard.errors[:parameters]).to be_present
    end

    it "rejects a default that is not an ISO date" do
      dashboard = build_dashboard(
        parameters: [{ "name" => "start_date", "type" => "date", "default" => "2026-08-01' OR '1'='1" }]
      )

      expect(dashboard).not_to be_valid
      expect(dashboard.errors[:parameters]).to be_present
    end
  end

  describe "archiving" do
    let(:dashboard) do
      described_class.create!(
        name: "Ops overview",
        collection: root_collection,
        creator: admin
      )
    end

    it "starts active" do
      expect(dashboard.archived?).to be(false)
      expect(described_class.active).to include(dashboard)
      expect(described_class.archived).not_to include(dashboard)
    end

    it "archives and unarchives" do
      dashboard.archive!

      expect(dashboard.archived?).to be(true)
      expect(dashboard.archived_at).to be_present
      expect(described_class.active).not_to include(dashboard)
      expect(described_class.archived).to include(dashboard)

      dashboard.unarchive!

      expect(dashboard.archived?).to be(false)
      expect(dashboard.archived_at).to be_nil
    end
  end
end
