# frozen_string_literal: true

require_relative "../../../rails_helper"

RSpec.describe "Admin users management", type: :request do
  let(:admin) { Nquery::User.find_by!(email: "admin@nquery.dev") }
  let(:analyst) { Nquery::User.find_by!(email: "analyst@nquery.dev") }

  def sign_in_as_admin
    post "/login", params: { email: admin.email, password: "password123" }
  end

  describe "GET /admin/users/new" do
    it "renders the new user form" do
      sign_in_as_admin
      get "/admin/users/new"
      expect(response).to have_http_status(:ok)
    end
  end

  describe "POST /admin/users" do
    it "creates a user" do
      sign_in_as_admin
      group = Nquery::Group.find_by!(name: "Engineering")

      expect {
        post "/admin/users", params: {
          user: {
            email: "newadmin@example.com",
            first_name: "New",
            last_name: "Admin",
            password: "password123",
            password_confirmation: "password123"
          },
          group_ids: [group.id]
        }
      }.to change(Nquery::User, :count).by(1)

      expect(response).to redirect_to("/admin/users")
    end

    it "renders errors for invalid users" do
      sign_in_as_admin

      post "/admin/users", params: { user: { email: "" } }

      expect(response).to have_http_status(:unprocessable_content)
    end
  end

  describe "GET /admin/users/:id" do
    it "shows a user" do
      sign_in_as_admin
      get "/admin/users/#{analyst.id}"
      expect(response).to have_http_status(:ok)
      expect(response.body).to include(analyst.email)
    end
  end

  describe "PATCH /admin/users/:id" do
    it "updates a user" do
      sign_in_as_admin
      group = Nquery::Group.find_by!(name: "Engineering")

      patch "/admin/users/#{analyst.id}", params: {
        user: { first_name: "Updated", last_name: "Analyst" },
        group_ids: [group.id]
      }

      expect(response).to redirect_to("/admin/users")
      expect(analyst.reload.first_name).to eq("Updated")
    end

    it "renders errors for invalid updates" do
      sign_in_as_admin

      patch "/admin/users/#{analyst.id}", params: { user: { email: "" } }

      expect(response).to have_http_status(:unprocessable_content)
    end
  end
end
