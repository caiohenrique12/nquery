# frozen_string_literal: true

require_relative "../../rails_helper"

RSpec.describe "Registrations", type: :request do
  describe "GET /signup" do
    it "renders the signup form" do
      get "/signup"

      expect(response).to have_http_status(:ok)
    end

    it "redirects signed-in users to root" do
      post "/login", params: { email: "admin@nquery.dev", password: "password123" }

      get "/signup"

      expect(response).to redirect_to("/")
    end
  end

  describe "POST /signup" do
    it "creates a user and signs them in" do
      expect {
        post "/signup", params: {
          user: {
            email: "newuser@example.com",
            first_name: "New",
            last_name: "User",
            password: "password123",
            password_confirmation: "password123"
          }
        }
      }.to change(Nquery::User, :count).by(1)

      user = Nquery::User.find_by!(email: "newuser@example.com")
      expect(user.personal_collection).to be_present
      expect(response).to redirect_to("/")
      expect(flash[:notice]).to eq("Welcome to nquery!")
    end

    it "renders errors for invalid signup" do
      post "/signup", params: { user: { email: "", password: "short" } }

      expect(response).to have_http_status(:unprocessable_content)
    end
  end
end
