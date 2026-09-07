# frozen_string_literal: true

require_relative "../../rails_helper"

RSpec.describe "Public links", type: :request do
  let(:admin) { Nquery::User.find_by!(email: "admin@nquery.dev") }
  let(:chart) { Nquery::Chart.find_by!(name: "Revenue by month") }
  let(:dashboard) { Nquery::Dashboard.find_by!(name: "Executive overview") }

  describe "GET /public/charts/:uuid" do
    it "renders a publicly shared chart" do
      Nquery.configuration.public_sharing_enabled = true
      chart.share_publicly!(user: admin)

      get "/public/charts/#{chart.public_uuid}"

      expect(response).to have_http_status(:ok)
      expect(response.body).to include(chart.name)
      expect(response.body).to include("2026-01")
      expect(response.headers["X-Frame-Options"]).to be_blank
    end

    it "returns not found when the chart is unshared" do
      Nquery.configuration.public_sharing_enabled = true
      chart.unshare_publicly!

      get "/public/charts/#{SecureRandom.uuid}"

      expect(response).to have_http_status(:not_found)
      expect(response.body).to include("This visualization is not available.")
    end

    it "returns not found when public sharing is disabled" do
      chart.share_publicly!(user: admin)

      get "/public/charts/#{chart.public_uuid}"

      expect(response).to have_http_status(:not_found)
    end
  end

  describe "GET /public/dashboards/:uuid" do
    it "renders a publicly shared dashboard" do
      Nquery.configuration.public_sharing_enabled = true
      dashboard.share_publicly!(user: admin)

      get "/public/dashboards/#{dashboard.public_uuid}"

      expect(response).to have_http_status(:ok)
      expect(response.body).to include(dashboard.name)
      expect(response.body).to include(chart.name)
      expect(response.body).to include("nq-embed-grid")
    end

    it "returns not found when public sharing is disabled" do
      dashboard.share_publicly!(user: admin)

      get "/public/dashboards/#{dashboard.public_uuid}"

      expect(response).to have_http_status(:not_found)
    end
  end
end
