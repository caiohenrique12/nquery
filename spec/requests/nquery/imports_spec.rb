# frozen_string_literal: true

require_relative "../../rails_helper"

RSpec.describe "Imports", type: :request do
  let(:admin) { Nquery::User.find_by!(email: "admin@nquery.dev") }
  let(:csv_file) do
    file = Tempfile.new(["import", ".csv"])
    file.write("name,value\nAlice,1\nBob,2\n")
    file.rewind
    file
  end

  def sign_in_as_admin
    sign_in_with_devise(email: "admin@nquery.dev")
  end

  after do
    csv_file.close
    csv_file.unlink
  end

  describe "GET /imports/new" do
    it "renders the import form" do
      sign_in_as_admin
      get "/imports/new"

      expect(response).to have_http_status(:ok)
    end
  end

  describe "POST /imports" do
    before { sign_in_as_admin }

    it "imports a CSV file" do
      expect {
        post "/imports", params: {
          file: Rack::Test::UploadedFile.new(csv_file.path, "text/csv"),
          name: "Sales import",
          column_mapping: '{"name":"name","value":"value"}'
        }
      }.to change(Nquery::CsvUpload, :count).by(1)
        .and change(Nquery::DataSource, :count).by(1)

      expect(response).to redirect_to("/")
      expect(flash[:notice]).to include("Sales import")
    end

    it "handles import errors" do
      post "/imports", params: { name: "Broken import" }

      expect(response).to have_http_status(:unprocessable_content)
      expect(flash[:alert]).to be_present
    end

    it "defaults invalid column mapping JSON to an empty hash" do
      post "/imports", params: {
        file: Rack::Test::UploadedFile.new(csv_file.path, "text/csv"),
        name: "Mapping import",
        column_mapping: "not-json"
      }

      expect(response).to redirect_to("/")
    end

    it "denies access to non-curators" do
      viewer = Nquery::User.create!(email: "viewer@example.com", password: "password123", confirmed_at: Time.current).tap(&:ensure_all_users_membership!)
      sign_in_with_devise(email: viewer.email)

      post "/imports", params: {
        file: Rack::Test::UploadedFile.new(csv_file.path, "text/csv"),
        name: "Denied import"
      }

      expect(response).to redirect_to("/")
      expect(flash[:alert]).to include("permission")
    end
  end
end
