# frozen_string_literal: true

require_relative "../../rails_helper"

RSpec.describe Nquery::User do
  describe "confirmable" do
    it "expires confirmation within 1 hour" do
      expect(described_class.confirm_within).to eq(1.hour)
    end
  end

  describe ".create" do
    context "when password is present" do
      it "stays unconfirmed until skip_confirmation! or confirm" do
        user = described_class.create!(
          email: "passworded@example.com",
          password: "password123",
          password_confirmation: "password123"
        )

        expect(user.confirmed_at).to be_nil
        expect(user).not_to be_confirmed
      end
    end

    context "when confirmed_at is nil and password is present" do
      it "respects the explicit unconfirmed state" do
        user = described_class.create!(
          email: "pending@example.com",
          password: "password123",
          password_confirmation: "password123",
          confirmed_at: nil
        )

        expect(user.confirmed_at).to be_nil
      end
    end

    context "when password is blank" do
      it "creates an unconfirmed user with a confirmation token" do
        user = described_class.create!(
          email: "onboarding@example.com",
          first_name: "Ada",
          last_name: "Admin"
        )

        expect(user.confirmed_at).to be_nil
        expect(user.confirmation_token).to be_present
      end
    end
  end

  describe "#active_for_authentication?" do
    it "is false for a deactivated user with inactive message" do
      user = described_class.create!(
        email: "inactive@example.com",
        password: "password123",
        password_confirmation: "password123",
        confirmed_at: Time.current
      )
      user.deactivate!

      expect(user).not_to be_active_for_authentication
      expect(user.inactive_message).to eq(:inactive)
    end
  end

  describe "#ensure_personal_collection!" do
    it "creates a personal collection when missing" do
      user = described_class.create!(
        email: "solo@example.com",
        password: "password123",
        password_confirmation: "password123",
        confirmed_at: Time.current
      )
      user.group_memberships.destroy_all

      collection = user.ensure_personal_collection!

      expect(collection.kind).to eq("personal")
      expect(collection.owner).to eq(user)
    end
  end

  describe "#active?" do
    it "reflects deactivated_at" do
      user = described_class.create!(
        email: "active@example.com",
        password: "password123",
        password_confirmation: "password123",
        confirmed_at: Time.current
      )
      expect(user).to be_active
      user.deactivate!
      expect(user).not_to be_active
    end
  end
end
