# frozen_string_literal: true

require_relative "../../rails_helper"

RSpec.describe "Home", type: :request do
  def sign_in_as_admin
    sign_in_with_devise(email: "admin@nquery.dev")
  end

  describe "GET /" do
    before { sign_in_as_admin }

    it "links to collections and dashboards" do
      get "/"

      expect(response).to have_http_status(:ok)
      expect(response.body).to include("Browse folders and content")
      expect(response.body).to include("View all your dashboards")
    end

    it "does not include an Analytics shortcut to the root collection" do
      get "/"

      expect(response.body).not_to include("Open Our analytics")
      expect(response.body).not_to include(">Analytics</span>")
    end
  end
end
