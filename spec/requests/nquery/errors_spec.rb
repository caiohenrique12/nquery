# frozen_string_literal: true

require_relative "../../rails_helper"

RSpec.describe "Error pages", type: :request do
  describe "unknown paths" do
    it "renders a branded 404 for /signup" do
      get "/signup"

      expect(response).to have_http_status(:not_found)
      expect(response.body).to include("Page not found")
      expect(response.body).not_to include("Routing Error")
      expect(response.body).not_to include("No route matches")
    end

    it "renders a branded 404 for other unmatched paths" do
      get "/this-path-does-not-exist"

      expect(response).to have_http_status(:not_found)
      expect(response.body).to include("Page not found")
      expect(response.body).not_to include("Routing Error")
    end
  end

  describe "missing records" do
    it "renders a branded 404 for ActiveRecord::RecordNotFound" do
      sign_in_with_devise(email: "admin@nquery.dev")

      get "/collections/0"

      expect(response).to have_http_status(:not_found)
      expect(response.body).to include("Page not found")
      expect(response.body).not_to include("ActiveRecord::RecordNotFound")
    end
  end

  describe "unhandled errors" do
    around do |example|
      previous = Rails.application.config.consider_all_requests_local
      Rails.application.config.consider_all_requests_local = false
      example.run
    ensure
      Rails.application.config.consider_all_requests_local = previous
    end

    it "renders a branded 500 page" do
      sign_in_with_devise(email: "admin@nquery.dev")
      allow_any_instance_of(Nquery::HomeController).to receive(:index).and_raise(RuntimeError, "boom")

      get "/"

      expect(response).to have_http_status(:internal_server_error)
      expect(response.body).to include("Something went wrong")
      expect(response.body).not_to include("RuntimeError")
      expect(response.body).not_to include("boom")
    end
  end
end
