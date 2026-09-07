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
