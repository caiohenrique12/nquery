# frozen_string_literal: true

require_relative "../../../rails_helper"

RSpec.describe "Admin logs", type: :request do
  def sign_in_as_admin
    sign_in_with_devise(email: "admin@nquery.dev")
  end

  def sign_in_as_analyst
    sign_in_with_devise(email: "analyst@nquery.dev")
  end

  let(:admin) { Nquery::User.find_by!(email: "admin@nquery.dev") }
  let(:query) { Nquery::Query.find_by!(name: "Monthly revenue") }
  let(:dashboard) { Nquery::Dashboard.find_by!(name: "Executive overview") }

  before do
    Nquery::Audit.create!(
      user: admin,
      query: query,
      statement: query.statement,
      status: "success",
      row_count: 3,
      duration_ms: 12,
      created_at: 2.days.ago
    )
  end

  it "redirects non-admins" do
    sign_in_as_analyst
    get "/admin/logs"

    expect(response).to redirect_to("/")
    expect(flash[:alert]).to eq("Admin access required.")
  end

  it "renders logs for admins" do
    sign_in_as_admin
    get "/admin/logs"

    expect(response).to have_http_status(:ok)
    expect(response.body).to include("Query logs")
    expect(response.body).to include(admin.name)
    expect(response.body).to include("success")
    expect(response.body).to include("Executive overview")
    expect(response.body).to include('class="nq-nav-link active" href="/admin/logs"')
  end

  it "does not show activity on the home page" do
    sign_in_as_admin
    get "/"

    expect(response).to have_http_status(:ok)
    expect(response.body).not_to include("<h2>Activity</h2>")
  end

  it "filters by user" do
    sign_in_as_admin
    get "/admin/logs", params: { user: "Admin" }

    expect(response).to have_http_status(:ok)
    expect(response.body).to include(admin.name)
  end

  it "filters by collection" do
    sign_in_as_admin
    collection = query.collection
    get "/admin/logs", params: { collection: collection.id }

    expect(response).to have_http_status(:ok)
    expect(response.body).to include(collection.name)
  end

  it "filters by dashboard" do
    sign_in_as_admin
    get "/admin/logs", params: { dashboard: dashboard.id }

    expect(response).to have_http_status(:ok)
    expect(response.body).to include(dashboard.name)
  end

  it "filters by date range" do
    sign_in_as_admin
    get "/admin/logs", params: { from: 3.days.ago.to_date, to: 1.day.ago.to_date }

    expect(response).to have_http_status(:ok)
    expect(response.body).to include(admin.name)
  end
end
