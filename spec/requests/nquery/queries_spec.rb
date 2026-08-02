# frozen_string_literal: true

require "nquery"
require_relative "../../rails_helper"

RSpec.describe "Nquery queries", type: :request do
  let(:data_source) { Nquery::DataSource.find_by!(key: "main") }
  let(:restricted_collection) do
    Nquery::Collection.create!(name: "Private collection", kind: "standard", parent: Nquery::Collection.roots.first)
  end
  let(:restricted_group) { Nquery::Group.create!(name: "Restricted", system_group: "custom") }
  let(:owner) do
    Nquery::User.create!(email: "owner@example.com", password: "password123", confirmed_at: Time.current).tap do |user|
      Nquery::GroupMembership.create!(user: user, group: restricted_group)
      user.ensure_all_users_membership!
    end
  end
  let(:outsider) do
    Nquery::User.create!(email: "outsider@example.com", password: "password123", confirmed_at: Time.current).tap(&:ensure_all_users_membership!)
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
    Nquery::DataPermission.create!(
      group: restricted_group,
      data_source: data_source,
      permission_type: "view_data",
      access_level: "can_view"
    )
    Nquery::DataPermission.create!(
      group: restricted_group,
      data_source: data_source,
      permission_type: "create_queries",
      access_level: "query_builder_and_native"
    )
  end

  def sign_in_as(user)
    sign_in_with_devise(email: user.email)
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

    expect(response).to have_http_status(:unprocessable_content)
    expect(JSON.parse(response.body)).to include("error")
    expect(query.reload.statement).to eq("SELECT 1 AS value")
  end

  it "renders the new query form" do
    sign_in_as(owner)

    get "/queries/new"

    expect(response).to have_http_status(:ok)
  end

  it "creates a query" do
    sign_in_as(owner)

    expect {
      post "/queries", params: {
        query: {
          name: "New query",
          statement: "SELECT 10 AS value",
          data_source_id: data_source.id,
          collection_id: restricted_collection.id
        }
      }
    }.to change(Nquery::Query, :count).by(1)

    expect(response).to be_redirect
  end

  it "does not create a query with mutating SQL" do
    sign_in_as(owner)

    expect {
      post "/queries", params: {
        query: {
          name: "Evil query",
          statement: "DELETE FROM users",
          data_source_id: data_source.id,
          collection_id: restricted_collection.id
        }
      }
    }.not_to change(Nquery::Query, :count)

    expect(response).to have_http_status(:unprocessable_content)
  end

  it "does not update a query with mutating SQL" do
    sign_in_as(owner)

    patch "/queries/#{query.id}",
          params: { query: { statement: "UPDATE users SET email = 'hacked@example.com'" } },
          as: :json

    expect(response).to have_http_status(:unprocessable_content)
    expect(JSON.parse(response.body)["error"]).to match(/SELECT|read-only|not allowed/i)
    expect(query.reload.statement).to eq("SELECT 1 AS value")
  end

  it "renders the new template when query creation fails" do
    sign_in_as(owner)
    allow_any_instance_of(Nquery::Query).to receive(:save).and_return(false)

    post "/queries", params: {
      query: {
        name: "Broken query",
        statement: "SELECT 1",
        data_source_id: data_source.id,
        collection_id: restricted_collection.id
      }
    }

    expect(response).to have_http_status(:unprocessable_content)
  end

  it "runs a query and returns JSON results" do
    sign_in_as(owner)

    post "/queries/run", params: { data_source_id: data_source.id, statement: "SELECT 42 AS value" }, as: :json

    expect(response).to have_http_status(:ok)
    expect(JSON.parse(response.body)["columns"]).to include("value")
  end

  it "returns forbidden when query run lacks permissions" do
    sign_in_as(outsider)

    post "/queries/run", params: { data_source_id: data_source.id, statement: "SELECT 1" }, as: :json

    expect(response).to have_http_status(:forbidden)
  end

  it "returns errors when query run fails" do
    sign_in_as(owner)

    post "/queries/run", params: { data_source_id: data_source.id, statement: "DELETE FROM users" }, as: :json

    expect(response).to have_http_status(:unprocessable_content)
  end

  it "returns forbidden when the query runner raises a permission error" do
    sign_in_as(owner)
    allow(Nquery::QueryRunner).to receive(:new).and_return(
      instance_double(Nquery::QueryRunner, run: -> { raise Nquery::QueryRunner::PermissionError, "denied" })
    )
    runner = instance_double(Nquery::QueryRunner)
    allow(Nquery::QueryRunner).to receive(:new).and_return(runner)
    allow(runner).to receive(:run).and_raise(Nquery::QueryRunner::PermissionError, "denied")

    post "/queries/run", params: { data_source_id: data_source.id, statement: "SELECT 1" }, as: :json

    expect(response).to have_http_status(:forbidden)
  end

  it "returns forbidden JSON when collection access is denied" do
    sign_in_as(outsider)

    get "/queries/#{query.id}", as: :json

    expect(response).to have_http_status(:forbidden)
  end

  it "returns an empty schema when introspection fails" do
    sign_in_as(owner)
    allow(Nquery::DataSources::Adapter).to receive(:for).and_raise(StandardError, "boom")

    get "/queries/new"

    expect(response).to have_http_status(:ok)
  end
end
