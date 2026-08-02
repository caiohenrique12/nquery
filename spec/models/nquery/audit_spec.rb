# frozen_string_literal: true

require_relative "../../rails_helper"

RSpec.describe Nquery::Audit do
  let(:admin) { Nquery::User.find_by!(email: "admin@nquery.dev") }
  let(:data_source) { Nquery::DataSource.find_by!(key: "main") }
  let(:root_collection) { Nquery::Collection.roots.first }

  describe ".for_user" do
    before do
      query = Nquery::Query.create!(
        name: "Audit query",
        statement: "SELECT 1",
        data_source: data_source,
        creator: admin,
        collection: root_collection
      )
      described_class.create!(user: admin, query: query, statement: "SELECT 1", status: "success")
    end

    it "matches email and full name" do
      expect(described_class.for_user("admin")).to be_present
      expect(described_class.for_user("Admin User")).to be_present
    end

    it "uses CONCAT on MySQL adapters" do
      allow(described_class.connection).to receive(:adapter_name).and_return("Mysql2")
      expect(described_class.for_user("admin").to_sql).to include("CONCAT")
    end
  end
end
