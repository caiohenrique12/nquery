# frozen_string_literal: true

require_relative "../../../rails_helper"

RSpec.describe "Admin data sources", type: :request do
  let(:admin) { Nquery::User.find_by!(email: "admin@nquery.dev") }
  let(:analyst) { Nquery::User.find_by!(email: "analyst@nquery.dev") }

  def sign_in_as_admin
    post "/login", params: { email: admin.email, password: "password123" }
  end

  describe "GET /admin/data_sources" do
    it "lists data sources" do
      sign_in_as_admin
      get "/admin/data_sources"

      expect(response).to have_http_status(:ok)
      expect(response.body).to include("Main Database")
    end

    it "denies non-admin users" do
      post "/login", params: { email: analyst.email, password: "password123" }
      get "/admin/data_sources"

      expect(response).to redirect_to("/")
    end
  end

  describe "GET /admin/data_sources/new" do
    it "renders the new form" do
      sign_in_as_admin
      get "/admin/data_sources/new"

      expect(response).to have_http_status(:ok)
    end
  end

  describe "POST /admin/data_sources" do
    it "creates a data source" do
      sign_in_as_admin

      expect {
        post "/admin/data_sources", params: {
          data_source: { name: "Warehouse", adapter: "postgresql", connection_config: '{"host":"localhost"}' }
        }
      }.to change(Nquery::DataSource, :count).by(1)

      expect(response).to redirect_to("/admin/data_sources")
    end

    it "renders errors for invalid data sources" do
      sign_in_as_admin

      post "/admin/data_sources", params: { data_source: { name: "", adapter: "postgresql" } }

      expect(response).to have_http_status(:unprocessable_content)
    end
  end

  describe "PATCH /admin/data_sources/:id" do
    let(:data_source) { Nquery::DataSource.find_by!(name: "Main Database") }

    it "updates a data source" do
      sign_in_as_admin

      patch "/admin/data_sources/#{data_source.id}", params: {
        data_source: { name: "Primary Database", adapter: "rails", connection_config: "{}" }
      }

      expect(response).to redirect_to("/admin/data_sources")
      expect(data_source.reload.name).to eq("Primary Database")
    end

    it "renders errors for invalid updates" do
      sign_in_as_admin

      patch "/admin/data_sources/#{data_source.id}", params: {
        data_source: { name: "", adapter: "rails" }
      }

      expect(response).to have_http_status(:unprocessable_content)
    end
  end
end
