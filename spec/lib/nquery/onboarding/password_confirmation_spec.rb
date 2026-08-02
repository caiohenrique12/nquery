# frozen_string_literal: true

require_relative "../../../rails_helper"

RSpec.describe Nquery::Onboarding::PasswordConfirmation do
  describe ".call" do
    let(:user) do
      Nquery::User.create!(
        email: "founder@acme.example.com",
        first_name: "Ada",
        last_name: "Admin"
      )
    end

    let!(:organization) { Nquery::Organization.create!(name: "Acme") }

    before do
      Nquery::Organization.where.not(id: organization.id).delete_all
    end

    it "confirms the user, sets a password, and latches onboarding completion" do
      result = described_class.call(
        user: user,
        password: "password123",
        password_confirmation: "password123"
      )

      expect(result).to be_success
      expect(user.reload.confirmed?).to be(true)
      expect(user.valid_password?("password123")).to be(true)
      expect(organization.reload.onboarding_completed_at).to be_present
    end

    it "returns failure when passwords do not match" do
      result = described_class.call(
        user: user,
        password: "password123",
        password_confirmation: "different"
      )

      expect(result).not_to be_success
      expect(user.reload.confirmed?).to be(false)
      expect(organization.reload.onboarding_completed_at).to be_nil
    end

    it "returns failure when user is nil" do
      result = described_class.call(user: nil, password: "password123", password_confirmation: "password123")

      expect(result).not_to be_success
      expect(result.user).to be_nil
    end
  end
end
