# frozen_string_literal: true

require "nquery"
require_relative "../../rails_helper"

RSpec.describe "Nquery queries", type: :request do
  let(:data_source) { Nquery::DataSource.find_by!(name: "Main Database") }
  let(:restricted_collection) do
    Nquery::Collection.create!(name: "Private collection", kind: "standard", parent: Nquery::Collection.roots.first)
  end
  let(:restricted_group) { Nquery::Group.create!(name: "Restricted", system_group: "custom") }
  let(:owner) do
    Nquery::User.create!(email: "owner@example.com", password: "password123").tap do |user|
      Nquery::GroupMembership.create!(user: user, group: restricted_group)
      user.ensure_all_users_membership!
    end
  end
  let(:outsider) do
    Nquery::User.create!(email: "outsider@example.com", password: "password123").tap(&:ensure_all_users_membership!)
  end
  let!(:query) do
    Nquery::Query.create!(
      name: "Private query",
      statement: "SELECT 1 AS value",
      data_source: data_source,
      creator: owner,
      collection: restricted_collection
    )
  end

  before do
    Nquery::CollectionPermission.create!(
      group: restricted_group,
      collection: restricted_collection,
      access_level: "view"
    )
  end

  def sign_in_as(user)
    post "/login", params: { email: user.email, password: "password123" }
    follow_redirect! if response.redirect?
  end

  it "allows collection members to edit a query" do
    sign_in_as(owner)

    get "/queries/#{query.id}/edit"

    expect(response).to have_http_status(:ok)
  end

  it "denies outsiders access to another user's collection query" do
    sign_in_as(outsider)

    get "/queries/#{query.id}"

    expect(response).to redirect_to("/")
    expect(flash[:alert]).to include("permission")
  end

  it "denies outsiders access to edit a restricted query" do
    sign_in_as(outsider)

    get "/queries/#{query.id}/edit"

    expect(response).to redirect_to("/")
    expect(flash[:alert]).to include("permission")
  end
end
