# frozen_string_literal: true

require_relative "../../rails_helper"

RSpec.describe "Sessions", type: :request do
  describe "GET /login" do
    it "redirects signed-in users to root" do
      post "/login", params: { email: "admin@nquery.dev", password: "password123" }

      get "/login"

      expect(response).to redirect_to("/")
    end
  end

  describe "POST /login" do
    it "rejects invalid credentials" do
      post "/login", params: { email: "admin@nquery.dev", password: "wrong" }

      expect(response).to have_http_status(:unprocessable_content)
      expect(response.body).to include("Invalid email or password")
    end
  end

  describe "DELETE /logout" do
    it "signs the user out" do
      post "/login", params: { email: "admin@nquery.dev", password: "password123" }

      delete "/logout"

      expect(response).to redirect_to("/login")
      expect(flash[:notice]).to eq("Signed out.")
    end
  end
end
