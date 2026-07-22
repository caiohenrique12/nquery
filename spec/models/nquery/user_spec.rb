# frozen_string_literal: true

require_relative "../../rails_helper"

RSpec.describe Nquery::User do
  describe ".find_or_create_from_sso!" do
    let(:host_user) { double(id: 99, email: "sso@example.com", first_name: "SSO", name: nil) }

    it "creates a user and adds them to all users" do
      expect {
        described_class.find_or_create_from_sso!(host_user)
      }.to change(described_class, :count).by(1)

      user = described_class.find_by!(external_id: "99")
      expect(user.email).to eq("sso@example.com")
      expect(user.groups.pluck(:system_group)).to include("all_users")
    end

    it "is idempotent on repeat calls" do
      described_class.find_or_create_from_sso!(host_user)
      expect { described_class.find_or_create_from_sso!(host_user) }.not_to change(described_class, :count)
    end
  end

  describe "#ensure_personal_collection!" do
    it "creates a personal collection when missing" do
      user = described_class.create!(email: "solo@example.com", password: "password123")
      user.group_memberships.destroy_all

      collection = user.ensure_personal_collection!

      expect(collection.kind).to eq("personal")
      expect(collection.owner).to eq(user)
    end
  end

  describe "#active?" do
    it "reflects deactivated_at" do
      user = described_class.create!(email: "active@example.com", password: "password123")
      expect(user).to be_active
      user.deactivate!
      expect(user).not_to be_active
    end
  end
end
