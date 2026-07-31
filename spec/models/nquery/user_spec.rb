# frozen_string_literal: true

require_relative "../../rails_helper"

RSpec.describe Nquery::User do
  describe "#ensure_personal_collection!" do
    it "creates a personal collection when missing" do
      user = described_class.create!(email: "solo@example.com", password: "password123", password_confirmation: "password123", confirmed_at: Time.current)
      user.group_memberships.destroy_all

      collection = user.ensure_personal_collection!

      expect(collection.kind).to eq("personal")
      expect(collection.owner).to eq(user)
    end
  end

  describe "#active?" do
    it "reflects deactivated_at" do
      user = described_class.create!(email: "active@example.com", password: "password123", password_confirmation: "password123", confirmed_at: Time.current)
      expect(user).to be_active
      user.deactivate!
      expect(user).not_to be_active
    end
  end
end
