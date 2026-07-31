# frozen_string_literal: true

require "nquery"
require_relative "../../rails_helper"

RSpec.describe "Nquery collection authorization", type: :request do
  let(:data_source) { Nquery::DataSource.find_by!(key: "main") }
  let(:restricted_collection) do
    Nquery::Collection.create!(name: "Finance", kind: "standard", parent: Nquery::Collection.roots.first)
  end
  let(:finance_group) { Nquery::Group.create!(name: "Finance", system_group: "custom") }
  let(:member) do
    Nquery::User.create!(email: "finance@example.com", password: "password123").tap do |user|
      Nquery::GroupMembership.create!(user: user, group: finance_group)
      user.ensure_all_users_membership!
    end
  end
  let(:outsider) do
    Nquery::User.create!(email: "guest@example.com", password: "password123").tap(&:ensure_all_users_membership!)
  end
  let!(:chart) do
    query = Nquery::Query.create!(
      name: "Finance query",
      statement: "SELECT 1 AS value",
      data_source: data_source,
      creator: member,
      collection: restricted_collection
    )
    Nquery::Chart.create!(
      name: "Finance chart",
      query: query,
      collection: restricted_collection,
      creator: member,
      visualization: { "type" => "table" }
    )
  end
  let!(:dashboard) do
    Nquery::Dashboard.create!(
      name: "Finance dashboard",
      collection: restricted_collection,
      creator: member
    )
  end

  before do
    Nquery::CollectionPermission.create!(
      group: finance_group,
      collection: restricted_collection,
      access_level: "view"
    )
  end

  def sign_in_as(user)
    post "/login", params: { email: user.email, password: "password123" }
    follow_redirect! if response.redirect?
  end

  it "allows members to browse restricted content" do
    sign_in_as(member)

    get "/collections/#{restricted_collection.id}"

    expect(response).to have_http_status(:ok)
    expect(response.body).to include("Finance chart")
    expect(response.body).to include("Finance dashboard")
  end

  it "hides restricted content from outsiders on collection show" do
    sign_in_as(outsider)

    get "/collections/#{restricted_collection.id}"

    expect(response).to redirect_to("/")
    expect(flash[:alert]).to include("permission")
  end

  it "denies outsiders access to restricted charts" do
    sign_in_as(outsider)

    get "/charts/#{chart.id}"

    expect(response).to redirect_to("/")
    expect(flash[:alert]).to include("permission")
  end

  it "denies outsiders access to restricted dashboards" do
    sign_in_as(outsider)

    get "/dashboards/#{dashboard.id}"

    expect(response).to redirect_to("/")
    expect(flash[:alert]).to include("permission")
  end
end
