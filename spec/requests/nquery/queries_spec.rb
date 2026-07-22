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

  it "returns schema tables with columns for authenticated users" do
    admin = Nquery::User.find_by!(email: "admin@nquery.dev")
    sign_in_as(admin)

    get "/queries/schema", params: { data_source_id: data_source.id }

    expect(response).to have_http_status(:ok)
    payload = JSON.parse(response.body)
    expect(payload["tables"]).not_to be_empty
    expect(payload["tables"].first).to include("name", "columns")
    expect(payload["tables"].first["columns"].first).to include("name", "type")
  end

  it "updates a query statement via JSON for autosave and format" do
    sign_in_as(owner)

    patch "/queries/#{query.id}",
          params: { query: { statement: "SELECT 2 AS value" } },
          as: :json

    expect(response).to have_http_status(:ok)
    expect(JSON.parse(response.body)).to include("ok" => true, "notice" => "Query saved.")
    expect(query.reload.statement).to eq("SELECT 2 AS value")
  end

  it "returns JSON errors when a query update fails" do
    sign_in_as(owner)

    patch "/queries/#{query.id}",
          params: { query: { name: "", statement: "SELECT 3 AS value" } },
          as: :json

    expect(response).to have_http_status(:unprocessable_entity)
    expect(JSON.parse(response.body)).to include("error")
    expect(query.reload.statement).to eq("SELECT 1 AS value")
  end
end
