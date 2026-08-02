# frozen_string_literal: true

require_relative "../../../rails_helper"

RSpec.describe Nquery::Onboarding::AdminProvisioner do
  describe ".call" do
    it "creates an unconfirmed admin with group memberships" do
      user = Nquery::User.new(
        email: "founder@acme.example.com",
        first_name: "Ada",
        last_name: "Admin"
      )

      result = described_class.call(user)

      expect(result.user).to be_persisted
      expect(result.mail_delivered?).to be(true)
      expect(result.user.confirmed?).to be(false)
      expect(result.user.admin?).to be(true)
      expect(result.user.personal_collection).to be_present
    end

    it "still creates the admin when confirmation email delivery fails" do
      user = Nquery::User.new(
        email: "founder@acme.example.com",
        first_name: "Ada",
        last_name: "Admin"
      )
      allow_any_instance_of(ActionMailer::MessageDelivery).to receive(:deliver_now)
        .and_raise(Errno::ECONNREFUSED)

      result = described_class.call(user)

      expect(result.user).to be_persisted
      expect(result.mail_delivered?).to be(false)
      expect(result.user.admin?).to be(true)
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
