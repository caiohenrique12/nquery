# frozen_string_literal: true

require_relative "../../rails_helper"

RSpec.describe "Embed pages", type: :request do
  let(:admin) { Nquery::User.find_by!(email: "admin@nquery.dev") }
  let(:chart) { Nquery::Chart.find_by!(name: "Revenue by month") }
  let(:dashboard) { Nquery::Dashboard.find_by!(name: "Executive overview") }

  describe "GET /embed/charts/:token" do
    it "renders a chart with a valid token" do
      result = Nquery::EmbedTokenService.sign(
        resource_type: "Nquery::Chart",
        resource_id: chart.id,
        creator: admin
      )

      get "/embed/charts/show", params: { token: result[:signed_token] }

      expect(response).to have_http_status(:ok)
      expect(response.body).to include(chart.name)
    end

    it "rejects invalid tokens" do
      get "/embed/charts/show", params: { token: "invalid.token" }

      expect(response).to have_http_status(:forbidden)
      expect(response.body).to eq("Invalid or expired embed token")
    end
  end

  describe "GET /embed/dashboards/:token" do
    it "renders a dashboard with a valid token" do
      result = Nquery::EmbedTokenService.sign(
        resource_type: "Nquery::Dashboard",
        resource_id: dashboard.id,
        creator: admin
      )

      get "/embed/dashboards/show", params: { token: result[:signed_token] }

      expect(response).to have_http_status(:ok)
      expect(response.body).to include(dashboard.name)
    end

    it "rejects invalid tokens" do
      get "/embed/dashboards/show", params: { token: "invalid.token" }

      expect(response).to have_http_status(:forbidden)
      expect(response.body).to eq("Invalid or expired embed token")
    end
  end
end
