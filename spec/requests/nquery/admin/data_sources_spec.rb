# frozen_string_literal: true

require_relative "../../../rails_helper"

RSpec.describe "Admin data sources", type: :request do
  let(:admin) { Nquery::User.find_by!(email: "admin@nquery.dev") }
  let(:analyst) { Nquery::User.find_by!(email: "analyst@nquery.dev") }

  def sign_in_as_admin
    sign_in_with_devise(email: "admin@nquery.dev")
  end

  describe "GET /admin/data_sources" do
    it "lists data sources" do
      sign_in_as_admin
      get "/admin/data_sources"

      expect(response).to have_http_status(:ok)
      expect(response.body).to include("Application database")
    end

    it "denies non-admin users" do
      sign_in_with_devise(email: analyst.email)
      get "/admin/data_sources"

      expect(response).to redirect_to("/")
    end
  end

  describe "GET /admin/data_sources/new" do
    it "renders connection fields instead of JSON" do
      sign_in_as_admin
      get "/admin/data_sources/new"

      expect(response).to have_http_status(:ok)
      expect(response.body).to include('data-controller="data-source-form"')
      expect(response.body).to include("Host")
      expect(response.body).not_to include("Connection (JSON)")
    end
  end

  describe "POST /admin/data_sources" do
    it "creates a data source from connection fields" do
      sign_in_as_admin

      expect {
        post "/admin/data_sources", params: {
          data_source: {
            name: "Warehouse",
            adapter: "postgresql",
            host: "localhost",
            database: "warehouse",
            username: "reader",
            password: "secret-pass"
          }
        }
      }.to change(Nquery::DataSource, :count).by(1)

      data_source = Nquery::DataSource.find_by!(name: "Warehouse")
      expect(data_source.connection_config_hash).to include(
        "host" => "localhost",
        "database" => "warehouse",
        "username" => "reader",
        "password" => "secret-pass"
      )
      expect(response).to redirect_to("/admin/data_sources")
    end

    it "renders errors for invalid data sources" do
      sign_in_as_admin

      post "/admin/data_sources", params: { data_source: { name: "", adapter: "postgresql" } }

      expect(response).to have_http_status(:unprocessable_content)
    end
  end

  describe "PATCH /admin/data_sources/:id" do
    let(:data_source) do
      Nquery::DataSource.create!(
        name: "Warehouse",
        adapter: "postgresql",
        connection_fields_submitted: true,
        host: "localhost",
        database: "warehouse",
        username: "reader",
        password: "secret-pass"
      )
    end

    it "updates a data source" do
      sign_in_as_admin

      patch "/admin/data_sources/#{data_source.id}", params: {
        data_source: {
          name: "Primary Warehouse",
          adapter: "postgresql",
          host: "db.internal",
          database: "warehouse",
          username: "reader",
          password: ""
        }
      }

      expect(response).to redirect_to("/admin/data_sources")
      expect(data_source.reload.name).to eq("Primary Warehouse")
      expect(data_source.connection_config_hash["host"]).to eq("db.internal")
      expect(data_source.connection_config_hash["password"]).to eq("secret-pass")
    end

    it "does not render the stored password on edit" do
      sign_in_as_admin

      get "/admin/data_sources/#{data_source.id}/edit"

      expect(response).to have_http_status(:ok)
      expect(response.body).not_to include("secret-pass")
      expect(response.body).to include("Leave blank to keep current password")
    end

    it "renders errors for invalid updates" do
      sign_in_as_admin

      patch "/admin/data_sources/#{data_source.id}", params: {
        data_source: { name: "", adapter: "postgresql", host: "localhost", database: "warehouse", username: "reader" }
      }

      expect(response).to have_http_status(:unprocessable_content)
    end
  end
end
