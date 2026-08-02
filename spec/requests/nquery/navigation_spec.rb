# frozen_string_literal: true

require_relative "../../rails_helper"

RSpec.describe "Navigation layout", type: :request do
  def sign_in_as_admin
    sign_in_with_devise(email: "admin@nquery.dev")
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

  it "renders breadcrumbs on collection edit" do
    sign_in_as_admin
    collection = Nquery::Collection.create!(name: "Marketing", kind: "standard", parent: Nquery::Collection.roots.first)

    get "/collections/#{collection.id}/edit"

    expect(response.body).to include("Marketing")
  end

  it "renders breadcrumbs on admin user pages" do
    sign_in_as_admin
    user = Nquery::User.find_by!(email: "analyst@nquery.dev")

    get "/admin/users/#{user.id}"
    expect(response).to have_http_status(:ok)

    get "/admin/users/#{user.id}/edit"
    expect(response).to have_http_status(:ok)

    get "/admin/users/new"
    expect(response).to have_http_status(:ok)
  end

  it "renders breadcrumbs on admin group and data source pages" do
    sign_in_as_admin
    group = Nquery::Group.find_by!(name: "Engineering")
    data_source = Nquery::DataSource.find_by!(key: "main")

    get "/admin/groups/#{group.id}"
    expect(response).to have_http_status(:ok)

    get "/admin/data_sources/#{data_source.id}/edit"
    expect(response).to have_http_status(:ok)
  end

  it "renders breadcrumbs on dashboard and standalone chart pages" do
    sign_in_as_admin
    dashboard = Nquery::Dashboard.find_by!(name: "Executive overview")
    chart = Nquery::Chart.find_by!(name: "Revenue by month")

    get "/dashboards/#{dashboard.id}/edit"
    expect(response).to have_http_status(:ok)

    get "/charts/#{chart.id}/edit"
    expect(response).to have_http_status(:ok)

    get "/charts/#{chart.id}/embed"
    expect(response).to have_http_status(:ok)
  end

  it "renders breadcrumbs on admin group pages" do
    sign_in_as_admin
    group = Nquery::Group.find_by!(name: "Engineering")

    get "/admin/groups/#{group.id}/edit"
    expect(response).to have_http_status(:ok)

    get "/admin/groups/new"
    expect(response).to have_http_status(:ok)
  end

  it "renders breadcrumbs on query pages" do
    sign_in_as_admin
    query = Nquery::Query.find_by!(name: "Monthly revenue")

    get "/queries/#{query.id}/edit"
    expect(response).to have_http_status(:ok)

    get "/queries/new"
    expect(response).to have_http_status(:ok)
  end

  it "renders breadcrumbs on import and permissions pages" do
    sign_in_as_admin

    get "/imports/new"
    expect(response).to have_http_status(:ok)

    get "/admin/permissions/by_group"
    expect(response).to have_http_status(:ok)
  end
end
