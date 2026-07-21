# frozen_string_literal: true

require_relative "../../rails_helper"

RSpec.describe "Navigation layout", type: :request do
  def sign_in_as_admin
    post "/login", params: { email: "admin@nquery.dev", password: "password123" }
  end

  it "redirects /browse to /collections" do
    sign_in_as_admin
    get "/browse"

    expect(response).to redirect_to("/collections")
  end

  it "renders sidebar and breadcrumbs on collections index" do
    sign_in_as_admin
    get "/collections"

    expect(response).to have_http_status(:ok)
    expect(response.body).to include('class="nq-sidebar"')
    expect(response.body).to include('class="nq-nav-link active" href="/collections"')
    expect(response.body).to include('class="nq-breadcrumbs"')
    expect(response.body).to include('<a href="/">Home</a>')
    expect(response.body).to include('<span aria-current="page">Collections</span>')
  end

  it "renders collection name in breadcrumbs on show" do
    sign_in_as_admin
    root_collection = Nquery::Collection.roots.first

    get "/collections/#{root_collection.id}"

    expect(response).to have_http_status(:ok)
    expect(response.body).to include('<a href="/collections">Collections</a>')
    expect(response.body).to include("<span aria-current=\"page\">#{root_collection.name}</span>")
  end

  it "renders dashboard name in breadcrumbs on show" do
    sign_in_as_admin
    dashboard = Nquery::Dashboard.find_by!(name: "Executive overview")

    get "/dashboards/#{dashboard.id}"

    expect(response).to have_http_status(:ok)
    expect(response.body).to include('<a href="/dashboards">Dashboards</a>')
    expect(response.body).to include("<span aria-current=\"page\">#{dashboard.name}</span>")
  end

  it "renders active admin sidebar item on groups" do
    sign_in_as_admin
    get "/admin/groups"

    expect(response).to have_http_status(:ok)
    expect(response.body).to include('class="nq-sidebar"')
    expect(response.body).to include('class="nq-nav-link active" href="/admin/groups"')
    expect(response.body).to include('<span aria-current="page">Groups</span>')
  end

  it "renders active admin sidebar item on logs" do
    sign_in_as_admin
    get "/admin/logs"

    expect(response).to have_http_status(:ok)
    expect(response.body).to include('class="nq-nav-link active" href="/admin/logs"')
    expect(response.body).to include('<span aria-current="page">Logs</span>')
  end
end
