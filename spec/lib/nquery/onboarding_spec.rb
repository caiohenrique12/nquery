# frozen_string_literal: true

require_relative "../../rails_helper"

RSpec.describe Nquery::Onboarding do
  around do |example|
    Nquery.reset_configuration!
    Nquery.configure { |config| config.authentication_provider = :devise }
    example.run
  end

  describe ".required?" do
    it "is the inverse of complete?" do
      expect(described_class.required?).to eq(!described_class.complete?)
    end
  end

  describe ".complete?" do
    before do
      Nquery::Organization.delete_all
      Nquery::GroupMembership.joins(:group)
        .where(nquery_groups: { system_group: "administrators" })
        .delete_all
    end

    it "is false when only an unconfirmed admin exists" do
      Nquery::Organization.create!(name: "Acme")
      admin = Nquery::User.create!(
        email: "admin@acme.example.com",
        first_name: "Ada",
        last_name: "Admin"
      )
      administrators = Nquery::Group.find_by!(system_group: "administrators")
      administrators.group_memberships.create!(user: admin)

      expect(described_class.complete?).to be(false)
    end

    it "is true when a confirmed admin exists" do
      Nquery::Organization.create!(name: "Acme")
      admin = Nquery::User.create!(
        email: "admin@acme.example.com",
        first_name: "Ada",
        last_name: "Admin",
        password: "password123",
        password_confirmation: "password123",
        confirmed_at: Time.current
      )
      administrators = Nquery::Group.find_by!(system_group: "administrators")
      administrators.group_memberships.create!(user: admin)

      expect(described_class.complete?).to be(true)
    end

    it "is true when an unconfirmed admin is pending confirmation" do
      Nquery::Organization.create!(name: "Acme")
      admin = Nquery::User.create!(
        email: "admin@acme.example.com",
        first_name: "Ada",
        last_name: "Admin"
      )
      administrators = Nquery::Group.find_by!(system_group: "administrators")
      administrators.group_memberships.create!(user: admin)

      expect(described_class.pending_admin_confirmation?).to be(true)
    end

    it "stays true when onboarding was latched even if admin membership is removed" do
      organization = Nquery::Organization.create!(name: "Acme", onboarding_completed_at: Time.current)
      admin = Nquery::User.create!(
        email: "admin@acme.example.com",
        first_name: "Ada",
        last_name: "Admin",
        password: "password123",
        password_confirmation: "password123",
        confirmed_at: Time.current
      )
      membership = Nquery::Group.find_by!(system_group: "administrators").group_memberships.create!(user: admin)
      membership.destroy!

      expect(organization.reload.onboarding_completed_at).to be_present
      expect(described_class.complete?).to be(true)
    end
  end
end
