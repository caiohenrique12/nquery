# frozen_string_literal: true

require_relative "../../../rails_helper"

RSpec.describe "Admin permissions", type: :request do
  let(:admin) { Nquery::User.find_by!(email: "admin@nquery.dev") }
  let(:root_collection) { Nquery::Collection.roots.first }
  let(:engineering_group) { Nquery::Group.find_by!(name: "Engineering") }
  let(:data_source) { Nquery::DataSource.find_by!(key: "main") }

  def sign_in_as_admin
    post "/login", params: { email: admin.email, password: "password123" }
  end

  describe "GET /admin/permissions" do
    it "redirects to by_group" do
      sign_in_as_admin
      get "/admin/permissions"

      expect(response).to redirect_to("/admin/permissions/by_group")
    end
  end

  describe "GET /admin/permissions/by_group" do
    it "renders the group permissions view" do
      sign_in_as_admin
      get "/admin/permissions/by_group"

      expect(response).to have_http_status(:ok)
      expect(response.body).to include("Engineering")
    end

    it "selects a specific group" do
      sign_in_as_admin
      get "/admin/permissions/by_group", params: { group_id: engineering_group.id }

      expect(response).to have_http_status(:ok)
    end
  end

  describe "GET /admin/permissions/by_data_source" do
    it "renders the data source permissions view" do
      sign_in_as_admin
      get "/admin/permissions/by_data_source", params: { data_source_id: data_source.id }

      expect(response).to have_http_status(:ok)
      expect(response.body).to include(data_source.name)
    end
  end

  describe "GET /admin/permissions/by_collection" do
    it "renders the collection permissions view with warnings" do
      sign_in_as_admin
      restricted_group = Nquery::Group.create!(name: "Restricted", system_group: "custom")
      Nquery::CollectionPermission.find_by!(group: Nquery::Group.find_by!(system_group: "all_users"), collection: root_collection)
      Nquery::CollectionPermission.create!(group: restricted_group, collection: root_collection, access_level: "no_access")

      get "/admin/permissions/by_collection", params: { collection_id: root_collection.id }

      expect(response).to have_http_status(:ok)
      expect(response.body).to include("All Users is more permissive than Restricted")
    end
  end

  describe "GET /admin/permissions/by_group warnings" do
    it "shows warnings when all users is more permissive" do
      sign_in_as_admin
      restricted_group = Nquery::Group.create!(name: "Restricted viewers", system_group: "custom")
      Nquery::CollectionPermission.find_by!(group: Nquery::Group.find_by!(system_group: "all_users"), collection: root_collection)
      Nquery::CollectionPermission.create!(group: restricted_group, collection: root_collection, access_level: "no_access")

      get "/admin/permissions/by_group", params: { group_id: restricted_group.id }

      expect(response.body).to include("All Users has broader access than Restricted viewers")
    end
  end
end
