# frozen_string_literal: true

require_relative "../../../rails_helper"

RSpec.describe "Admin users", type: :request do
  def sign_in_as_admin
    sign_in_with_devise(email: "admin@nquery.dev")
  end

  let(:admin) { Nquery::User.find_by!(email: "admin@nquery.dev") }
  let(:analyst) { Nquery::User.find_by!(email: "analyst@nquery.dev") }

  describe "GET /admin/users" do
    it "renders disable and remove actions for other users" do
      sign_in_as_admin
      get "/admin/users"

      expect(response).to have_http_status(:ok)
      expect(response.body).to include(analyst.email)
      expect(response.body).to include("Disable")
      expect(response.body).to include("Remove")
    end

    it "does not show disable or remove actions for the signed-in user" do
      sign_in_as_admin
      get "/admin/users"

      admin_row = response.body[/admin@nquery\.dev.*?<\/tr>/m]
      expect(admin_row).to include("Edit")
      expect(admin_row).not_to include("Disable")
      expect(admin_row).not_to include("Remove")
    end
  end

  describe "PATCH /admin/users/:id/deactivate" do
    it "disables another user" do
      sign_in_as_admin
      patch "/admin/users/#{analyst.id}/deactivate"

      expect(response).to redirect_to("/admin/users")
      expect(flash[:notice]).to eq("#{analyst.name} has been disabled.")
      expect(analyst.reload.deactivated_at).to be_present
    end

    it "prevents disabling your own account" do
      sign_in_as_admin
      patch "/admin/users/#{admin.id}/deactivate"

      expect(response).to redirect_to("/admin/users")
      expect(flash[:alert]).to eq("You cannot disable your own account.")
      expect(admin.reload.deactivated_at).to be_nil
    end
  end

  describe "DELETE /admin/users/:id" do
    it "removes another user" do
      sign_in_as_admin
      delete "/admin/users/#{analyst.id}"

      expect(response).to redirect_to("/admin/users")
      expect(flash[:notice]).to eq("#{analyst.name} has been removed.")
      expect(Nquery::User.find_by(id: analyst.id)).to be_nil
    end

    it "prevents removing your own account" do
      sign_in_as_admin
      delete "/admin/users/#{admin.id}"

      expect(response).to redirect_to("/admin/users")
      expect(flash[:alert]).to eq("You cannot remove your own account.")
      expect(Nquery::User.find_by(id: admin.id)).to eq(admin)
    end
  end
end
