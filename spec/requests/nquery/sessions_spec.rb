# frozen_string_literal: true

require_relative "../../rails_helper"

RSpec.describe "Sessions", type: :request do
  include Nquery::Engine.routes.url_helpers

  def sign_in_admin!
    post nquery_user_session_path, params: {
      nquery_user: { email: "admin@nquery.dev", password: "password123" }
    }
  end

  describe "GET /login" do
    it "redirects signed-in users to root" do
      sign_in_admin!

      get new_nquery_user_session_path

      expect(response).to redirect_to(root_path)
    end
  end

  describe "POST Devise session" do
    it "rejects invalid credentials" do
      post nquery_user_session_path, params: {
        nquery_user: { email: "admin@nquery.dev", password: "wrong" }
      }

      expect(flash[:alert]).to be_present
      expect(request.env["warden"].user(:nquery_user)).to be_nil
    end
  end

  describe "DELETE Devise session" do
    it "signs the user out" do
      sign_in_admin!

      delete destroy_nquery_user_session_path

      expect(response).to redirect_to(new_nquery_user_session_path)
      expect(flash[:notice]).to eq(I18n.t("devise.sessions.signed_out"))
    end
  end
end
