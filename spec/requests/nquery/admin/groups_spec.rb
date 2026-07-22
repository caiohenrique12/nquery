# frozen_string_literal: true

require_relative "../../../rails_helper"

RSpec.describe "Admin groups", type: :request do
  let(:admin) { Nquery::User.find_by!(email: "admin@nquery.dev") }
  let(:analyst) { Nquery::User.find_by!(email: "analyst@nquery.dev") }
  let(:all_users_group) { Nquery::Group.find_by!(system_group: "all_users") }

  def sign_in_as_admin
    post "/login", params: { email: admin.email, password: "password123" }
  end

  describe "GET /admin/groups/:id" do
    it "shows group members and available users" do
      sign_in_as_admin
      group = Nquery::Group.find_by!(name: "Engineering")

      get "/admin/groups/#{group.id}"

      expect(response).to have_http_status(:ok)
      expect(response.body).to include(analyst.email)
    end
  end

  describe "POST /admin/groups" do
    it "creates a custom group" do
      sign_in_as_admin

      expect {
        post "/admin/groups", params: { group: { name: "Finance", description: "Finance team" } }
      }.to change(Nquery::Group, :count).by(1)

      expect(response).to redirect_to("/admin/groups")
      expect(Nquery::Group.find_by!(name: "Finance").system_group).to eq("custom")
    end

    it "renders errors for invalid groups" do
      sign_in_as_admin

      post "/admin/groups", params: { group: { name: "" } }

      expect(response).to have_http_status(:unprocessable_content)
    end
  end

  describe "PATCH /admin/groups/:id" do
    it "updates a group" do
      sign_in_as_admin
      group = Nquery::Group.create!(name: "Ops", system_group: "custom")

      patch "/admin/groups/#{group.id}", params: { group: { name: "Operations", description: "Ops team" } }

      expect(response).to redirect_to("/admin/groups")
      expect(group.reload.name).to eq("Operations")
    end

    it "renders errors for invalid updates" do
      sign_in_as_admin
      group = Nquery::Group.create!(name: "Ops", system_group: "custom")

      patch "/admin/groups/#{group.id}", params: { group: { name: "" } }

      expect(response).to have_http_status(:unprocessable_content)
    end
  end

  describe "POST /admin/groups/:id/add_member" do
    it "adds a user to the group" do
      sign_in_as_admin
      group = Nquery::Group.create!(name: "Ops", system_group: "custom")

      post "/admin/groups/#{group.id}/add_member", params: { user_id: analyst.id }

      expect(response).to redirect_to("/admin/groups/#{group.id}")
      expect(group.reload.users).to include(analyst)
    end
  end

  describe "DELETE /admin/groups/:id/remove_member" do
    it "removes a user from a custom group" do
      sign_in_as_admin
      group = Nquery::Group.find_by!(name: "Engineering")

      delete "/admin/groups/#{group.id}/remove_member", params: { user_id: analyst.id }

      expect(response).to redirect_to("/admin/groups/#{group.id}")
      expect(group.reload.users).not_to include(analyst)
    end

    it "does not remove members from the all users group" do
      sign_in_as_admin
      membership = all_users_group.group_memberships.find_by!(user: analyst)

      delete "/admin/groups/#{all_users_group.id}/remove_member", params: { user_id: analyst.id }

      expect(response).to redirect_to("/admin/groups/#{all_users_group.id}")
      expect(Nquery::GroupMembership.exists?(membership.id)).to be(true)
    end
  end
end
