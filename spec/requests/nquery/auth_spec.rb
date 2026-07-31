# frozen_string_literal: true

require_relative "../../rails_helper"

RSpec.describe "Authentication", type: :request do
  describe "protected routes" do
    it "redirects unauthenticated users to login" do
      get "/collections"

      expect(response).to redirect_to("/login")
      expect(flash[:alert]).to eq("Please sign in to continue.")
    end
  end

  describe "Devise sign-in" do
    around do |example|
      Nquery.reset_configuration!
      Nquery.configure { |config| config.authentication_provider = :devise }
      example.run
    end

    it "redirects unauthenticated users to login" do
      get "/collections"

      expect(response).to redirect_to("/login")
      expect(flash[:alert]).to eq("Please sign in to continue.")
    end

    it "rejects unconfirmed users" do
      user = Nquery::User.create!(
        email: "pending@acme.example.com",
        first_name: "Pending",
        last_name: "User",
        password: "password123",
        password_confirmation: "password123"
      )

      post "/login", params: { email: user.email, password: "password123" }

      expect(response).to have_http_status(:unprocessable_content)
      expect(flash[:alert]).to eq("Invalid email or password.")
    end

    it "signs in and signs out a confirmed user" do
      user = Nquery::User.find_by!(email: "admin@nquery.dev")
      user.update!(confirmed_at: Time.current) if user.confirmed_at.blank?

      post "/login", params: { email: user.email, password: "password123" }
      expect(response).to redirect_to("/")

      delete "/logout"
      expect(response).to redirect_to("/login")
      expect(flash[:notice]).to eq("Signed out.")

      get "/collections"
      expect(response).to redirect_to("/login")
    end
  end
end
