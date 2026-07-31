# frozen_string_literal: true

require_relative "../../../rails_helper"

RSpec.describe Nquery::Onboarding::AdminProvisioner do
  around do |example|
    Nquery.reset_configuration!
    Nquery.configure { |config| config.authentication_provider = :devise }
    example.run
  end

  describe ".call" do
    it "creates an unconfirmed admin with group memberships" do
      user = Nquery::User.new(
        email: "founder@acme.example.com",
        first_name: "Ada",
        last_name: "Admin"
      )

      result = described_class.call(user)

      expect(result).to be_persisted
      expect(result.confirmed?).to be(false)
      expect(result.admin?).to be(true)
      expect(result.personal_collection).to be_present
    end

    it "raises when the administrators group is missing" do
      allow(Nquery::Group).to receive(:find_by!).with(system_group: "administrators").and_raise(ActiveRecord::RecordNotFound)
      user = Nquery::User.new(
        email: "founder@acme.example.com",
        first_name: "Ada",
        last_name: "Admin"
      )

      expect { described_class.call(user) }.to raise_error(ActiveRecord::RecordNotFound)
    end
  end
end
