# frozen_string_literal: true

require "nquery"
require "spec_helper"

RSpec.describe Nquery::Permissions::Resolver do
  let(:admin_group) { Nquery::Group.create!(name: "Administrators", system_group: "administrators") }
  let(:user) { Nquery::User.create!(email: "test@example.com", password: "password123") }

  before do
    Nquery::GroupMembership.create!(user: user, group: admin_group)
  end

  it "identifies admin users" do
    resolver = described_class.new(user)
    expect(resolver.admin?).to be true
  end
end
