# frozen_string_literal: true

require_relative "../../rails_helper"

RSpec.describe "Sharing settings", type: :request do
  let(:admin) { Nquery::User.find_by!(email: "admin@nquery.dev") }
  let(:analyst) { Nquery::User.find_by!(email: "analyst@nquery.dev") }
  let(:chart) { Nquery::Chart.find_by!(name: "Revenue by month") }
  let(:dashboard) { Nquery::Dashboard.find_by!(name: "Executive overview") }

  def sign_in_as(user)
    sign_in_with_devise(email: user.email)
  end

  def enable_sharing!
    Nquery.configuration.public_sharing_enabled = true
    Nquery.configuration.static_embedding_enabled = true
  end

  describe "GET /charts/:id/embed" do
    before { sign_in_as(admin) }

    it "renders the sharing panel" do
      get "/charts/#{chart.id}/embed"

      expect(response).to have_http_status(:ok)
      expect(response.body).to include("Public link")
      expect(response.body).to include("Static embed")
    end
  end

  describe "GET /dashboards/:id/embed" do
    before { sign_in_as(admin) }

    it "renders the dashboard sharing panel" do
      get "/dashboards/#{dashboard.id}/embed"

      expect(response).to have_http_status(:ok)
      expect(response.body).to include("Embed: #{dashboard.name}")
      expect(response.body).to include("Public link")
    end
  end

  describe "public link lifecycle" do
    before do
      sign_in_as(admin)
      enable_sharing!
      chart.unshare_publicly!
    end

    it "creates and removes a public link" do
      post "/charts/#{chart.id}/public_link"

      expect(response).to redirect_to("/charts/#{chart.id}/embed")
      expect(chart.reload).to be_publicly_shared

      follow_redirect!
      expect(response.body).to include("/public/charts/#{chart.public_uuid}")
      expect(response.body).to include("loading=")

      delete "/charts/#{chart.id}/public_link"

      expect(response).to redirect_to("/charts/#{chart.id}/embed")
      expect(chart.reload).not_to be_publicly_shared
    end
  end

  describe "embed token lifecycle" do
    before do
      sign_in_as(admin)
      enable_sharing!
    end

    it "generates a token with the selected expiry" do
      post "/charts/#{chart.id}/embed_tokens", params: { expires_in: "1.day" }

      expect(response).to redirect_to("/charts/#{chart.id}/embed")
      token = chart.reload.active_embed_token
      expect(token).to be_present
      expect(token.expires_at).to be_within(2.seconds).of(1.day.from_now)
      expect(chart.enable_embedding?).to be(true)
    end

    it "revokes an active token" do
      result = Nquery::EmbedTokenService.sign(resource_type: "Nquery::Chart", resource_id: chart.id, creator: admin)
      record = Nquery::EmbedToken.find_by!(token: result[:token])

      delete "/charts/#{chart.id}/embed_tokens/#{record.id}"

      expect(response).to redirect_to("/charts/#{chart.id}/embed")
      expect(record.reload.active).to be(false)
    end

    it "generates a dashboard token" do
      post "/dashboards/#{dashboard.id}/embed_tokens", params: { expires_in: "never" }

      expect(response).to redirect_to("/dashboards/#{dashboard.id}/embed")
      token = dashboard.reload.active_embed_token
      expect(token).to be_present
      expect(token.expires_at).to be_nil
    end
  end

  describe "when the user only has view access" do
    before do
      sign_in_as(analyst)
      enable_sharing!
    end

    it "allows opening the embed page" do
      get "/charts/#{chart.id}/embed"

      expect(response).to have_http_status(:ok)
    end

    it "denies creating a public link" do
      post "/charts/#{chart.id}/public_link"

      expect(response).to redirect_to("/")
      expect(flash[:alert]).to include("permission")
    end

    it "denies generating an embed token" do
      post "/charts/#{chart.id}/embed_tokens", params: { expires_in: "1.hour" }

      expect(response).to redirect_to("/")
      expect(flash[:alert]).to include("permission")
    end
  end
end
