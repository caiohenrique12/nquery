# frozen_string_literal: true

require_relative "../../rails_helper"

RSpec.describe "Authentication", type: :request do
  include Nquery::Engine.routes.url_helpers

  def sign_in_with(email:, password:)
    post nquery_user_session_path, params: {
      nquery_user: { email: email, password: password }
    }
  end

  describe "protected routes" do
    it "redirects unauthenticated users to the Devise sign-in page" do
      get "/collections"

      expect(response).to redirect_to(new_nquery_user_session_path)
    end

    context "when the engine is mounted at a non-root path" do
      around do |example|
        Rails.application.routes.draw do
          mount Nquery::Engine, at: "/nquery"
        end
        example.run
      ensure
        Rails.application.reload_routes!
      end

      it "redirects unauthenticated users to the mount-prefixed login path" do
        get "/nquery/collections"

        expect(response).to redirect_to("/nquery/login")
      end
    end
  end

  describe "Devise sessions" do
    it "rejects unconfirmed users" do
      user = Nquery::User.create!(
        email: "pending@acme.example.com",
        first_name: "Pending",
        last_name: "User",
        password: "password123",
        password_confirmation: "password123",
        confirmed_at: nil
      )

      sign_in_with(email: user.email, password: "password123")

      expect(flash[:alert]).to eq(I18n.t("devise.failure.unconfirmed"))
      expect(request.env["warden"].user(:nquery_user)).to be_nil
    end

    it "signs in a confirmed user through Devise/Warden" do
      user = Nquery::User.find_by!(email: "admin@nquery.dev")
      user.confirm unless user.confirmed?

      sign_in_with(email: user.email, password: "password123")

      expect(response).to redirect_to(root_path)
      expect(request.env["warden"].user(:nquery_user)).to eq(user)
    end

    it "signs out through Devise" do
      user = Nquery::User.find_by!(email: "admin@nquery.dev")
      user.confirm unless user.confirmed?

      sign_in_with(email: user.email, password: "password123")
      delete destroy_nquery_user_session_path

      expect(response).to redirect_to(new_nquery_user_session_path)
      expect(flash[:notice]).to eq(I18n.t("devise.sessions.signed_out"))
      expect(request.env["warden"].user(:nquery_user)).to be_nil

      get "/collections"
      expect(response).to redirect_to(new_nquery_user_session_path)
    end

    it "rejects invalid credentials through Devise" do
      sign_in_with(email: "admin@nquery.dev", password: "wrong")

      expect(flash[:alert]).to be_present
      expect(request.env["warden"].user(:nquery_user)).to be_nil
    end
  end
end
