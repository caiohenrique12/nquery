# frozen_string_literal: true

require_relative "../../rails_helper"

RSpec.describe Nquery::Collection do
  let(:root_collection) { described_class.roots.first }

  describe "archiving" do
    let(:collection) do
      described_class.create!(name: "Marketing", kind: "standard", parent: root_collection)
    end

    it "starts active" do
      expect(collection.archived?).to be(false)
      expect(described_class.active).to include(collection)
      expect(described_class.archived).not_to include(collection)
    end

    it "archives and unarchives" do
      collection.archive!

      expect(collection.archived?).to be(true)
      expect(collection.archived_at).to be_present
      expect(described_class.active).not_to include(collection)
      expect(described_class.archived).to include(collection)

      collection.unarchive!

      expect(collection.archived?).to be(false)
      expect(collection.archived_at).to be_nil
    end
  end
end
