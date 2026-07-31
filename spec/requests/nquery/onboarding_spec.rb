# frozen_string_literal: true

require_relative "../../rails_helper"

RSpec.describe "Onboarding", type: :request do
  include Nquery::Engine.routes.url_helpers

  around do |example|
    Nquery.reset_configuration!
    Nquery.configure { |config| config.authentication_provider = :devise }
    example.run
  end

  before do
    ActionMailer::Base.deliveries.clear
  end

  describe "when onboarding is incomplete" do
    before do
      Nquery::Organization.delete_all
      Nquery::GroupMembership.joins(:group)
        .where(nquery_groups: { system_group: "administrators" })
        .delete_all
    end

    it "redirects visitors to the company step" do
      get "/collections"

      expect(response).to redirect_to("/onboarding/company/new")
    end

    it "renders the company step" do
      get "/onboarding/company/new"

      expect(response).to have_http_status(:ok)
      expect(response.body).to include("Set up your company")
    end

    it "renders the admin step after company setup" do
      post "/onboarding/company", params: {
        organization: { name: "Acme Analytics", website: "https://acme.example.com" }
      }

      get "/onboarding/admin/new"

      expect(response).to have_http_status(:ok)
      expect(response.body).to include("Create your admin account")
    end

    it "redirects the admin step when company setup is missing" do
      get "/onboarding/admin/new"

      expect(response).to redirect_to("/onboarding/company/new")
      expect(flash[:alert]).to eq("Please set up your company first.")
    end

    it "renders validation errors for an invalid admin" do
      post "/onboarding/company", params: {
        organization: { name: "Acme Analytics", website: "https://acme.example.com" }
      }

      post "/onboarding/admin", params: {
        user: { email: "", first_name: "Ada", last_name: "Admin" }
      }

      expect(response).to have_http_status(:unprocessable_content)
      expect(response.body).to include("field_with_errors")
    end

    it "redirects congrats when onboarding has not started" do
      get "/onboarding/congrats"

      expect(response).to redirect_to("/onboarding/company/new")
      expect(flash[:alert]).to eq("Please complete onboarding.")
    end

    it "renders the confirmation form for a valid token" do
      post "/onboarding/company", params: {
        organization: { name: "Acme Analytics", website: "https://acme.example.com" }
      }
      post "/onboarding/admin", params: {
        user: { email: "founder@acme.example.com", first_name: "Ada", last_name: "Admin" }
      }
      user = Nquery::User.find_by!(email: "founder@acme.example.com")

      get onboarding_confirm_path(confirmation_token: user.confirmation_token)

      expect(response).to have_http_status(:ok)
      expect(response.body).to include("password")
    end

    it "rejects an invalid confirmation show link" do
      get onboarding_confirm_path(confirmation_token: "invalid-token")

      expect(response).to redirect_to("/login")
      expect(flash[:alert]).to eq("Invalid confirmation link.")
    end

    it "re-renders confirmation when the password is invalid" do
      post "/onboarding/company", params: {
        organization: { name: "Acme Analytics", website: "https://acme.example.com" }
      }
      post "/onboarding/admin", params: {
        user: { email: "founder@acme.example.com", first_name: "Ada", last_name: "Admin" }
      }
      user = Nquery::User.find_by!(email: "founder@acme.example.com")

      patch onboarding_confirm_path(confirmation_token: user.confirmation_token), params: {
        user: { password: "password123", password_confirmation: "different" }
      }

      expect(response).to have_http_status(:unprocessable_content)
      expect(user.reload.confirmed?).to be(false)
    end

    it "completes the wizard and signs in the admin" do
      post "/onboarding/company", params: {
        organization: { name: "Acme Analytics", website: "https://acme.example.com" }
      }
      expect(response).to redirect_to("/onboarding/admin/new")

      expect {
        post "/onboarding/admin", params: {
          user: { email: "founder@acme.example.com", first_name: "Ada", last_name: "Admin" }
        }
      }.to change(ActionMailer::Base.deliveries, :size).by(1)

      expect(response).to redirect_to("/onboarding/congrats")
      follow_redirect!
      expect(response.body).to include("founder@acme.example.com")
      expect(response.body).to include("Check your email")

      user = Nquery::User.find_by!(email: "founder@acme.example.com")
      expect(user.confirmation_token).to be_present

      patch onboarding_confirm_path(confirmation_token: user.confirmation_token), params: {
        user: { password: "password123", password_confirmation: "password123" }
      }

      expect(response).to redirect_to("/")
      expect(user.reload.confirmed_at).to be_present
      expect(Nquery::Organization.first.onboarding_completed_at).to be_present
    end

    it "reuses the existing organization on repeated company submissions" do
      post "/onboarding/company", params: {
        organization: { name: "Acme Analytics", website: "https://acme.example.com" }
      }
      post "/onboarding/company", params: {
        organization: { name: "Acme Analytics Updated", website: "https://updated.example.com" }
      }

      expect(Nquery::Organization.count).to eq(1)
      expect(Nquery::Organization.first.name).to eq("Acme Analytics Updated")
      expect(response).to redirect_to("/onboarding/admin/new")
    end

    it "renders validation errors for an invalid organization" do
      post "/onboarding/company", params: { organization: { name: "" } }

      expect(response).to have_http_status(:unprocessable_content)
      expect(response.body).to include("field_with_errors")
    end

    it "rejects an invalid confirmation token" do
      patch onboarding_confirm_path(confirmation_token: "invalid-token"), params: {
        user: { password: "password123", password_confirmation: "password123" }
      }

      expect(response).to redirect_to("/login")
      expect(flash[:alert]).to eq("Invalid confirmation link.")
    end

    it "locks company and admin writes after an unconfirmed admin is created" do
      Nquery::Organization.create!(name: "Acme")
      user = Nquery::User.create!(
        email: "founder@acme.example.com",
        first_name: "Ada",
        last_name: "Admin"
      )
      Nquery::Group.find_by!(system_group: "administrators").group_memberships.create!(user: user)

      get "/onboarding/company/new"
      expect(response).to redirect_to("/onboarding/congrats")

      post "/onboarding/company", params: { organization: { name: "Evil Corp" } }
      expect(response).to redirect_to("/onboarding/congrats")
      expect(Nquery::Organization.first.name).to eq("Acme")

      post "/onboarding/admin", params: {
        user: { email: "evil@example.com", first_name: "Eve", last_name: "Il" }
      }
      expect(response).to redirect_to("/onboarding/congrats")
      expect(Nquery::User.find_by(email: "evil@example.com")).to be_nil
    end

    it "shows congrats with session email after admin create" do
      post "/onboarding/company", params: {
        organization: { name: "Acme Analytics", website: "https://acme.example.com" }
      }
      post "/onboarding/admin", params: {
        user: { email: "founder@acme.example.com", first_name: "Ada", last_name: "Admin" }
      }

      get "/onboarding/congrats"

      expect(response).to have_http_status(:ok)
      expect(response.body).to include("founder@acme.example.com")
    end

    it "shows a generic congrats page when pending confirmation without session" do
      Nquery::Organization.create!(name: "Acme")
      user = Nquery::User.create!(
        email: "founder@acme.example.com",
        first_name: "Ada",
        last_name: "Admin"
      )
      Nquery::Group.find_by!(system_group: "administrators").group_memberships.create!(user: user)

      get "/onboarding/congrats"

      expect(response).to have_http_status(:ok)
      expect(response.body).not_to include("founder@acme.example.com")
      expect(response.body).to include("Check your email")
    end
  end

  describe "when onboarding is complete" do
    it "locks the wizard" do
      get "/onboarding/company/new"

      expect(response).to redirect_to("/login")
    end

    it "stays locked after the last admin membership is removed" do
      organization = Nquery::Organization.first
      organization.update!(onboarding_completed_at: Time.current)
      admin = Nquery::User.find_by!(email: "admin@nquery.dev")
      Nquery::GroupMembership.joins(:group)
        .where(user: admin, nquery_groups: { system_group: "administrators" })
        .delete_all

      get "/onboarding/company/new"

      expect(response).to redirect_to("/login")
    end
  end

  describe "closed signup" do
    it "does not expose signup" do
      get "/signup"

      expect(response).to have_http_status(:not_found)
    end

    it "does not show create account on login" do
      get "/login"

      expect(response.body).not_to include("Create an account")
    end
  end
end
