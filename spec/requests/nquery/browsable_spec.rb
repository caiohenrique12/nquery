# frozen_string_literal: true

require_relative "../../rails_helper"

RSpec.describe "Collection authorization", type: :request do
  let(:root_collection) { Nquery::Collection.roots.first }
  let(:viewer_group) { Nquery::Group.create!(name: "Viewers", system_group: "custom") }
  let(:viewer) do
    Nquery::User.create!(email: "viewer@example.com", password: "password123", confirmed_at: Time.current).tap do |user|
      Nquery::GroupMembership.create!(user: user, group: viewer_group)
      user.ensure_all_users_membership!
    end
  end
  let(:owner) do
    Nquery::User.create!(email: "owner@example.com", password: "password123", confirmed_at: Time.current).tap do |user|
      user.ensure_all_users_membership!
      user.ensure_personal_collection!
    end
  end

  def sign_in_as(user)
    sign_in_with_devise(email: user.email)
  end

  it "hides personal collections from other users" do
    sign_in_as(viewer)

    get "/collections"

    expect(response.body).not_to include(owner.personal_collection.name)
  end

  it "filters collections for non-admin users" do
    restricted = Nquery::Collection.create!(name: "Hidden folder", kind: "standard", parent: root_collection)
    sign_in_as(viewer)

    get "/collections"

    expect(response.body).not_to include(restricted.name)
  end
end
