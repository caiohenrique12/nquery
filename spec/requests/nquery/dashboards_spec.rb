# frozen_string_literal: true

require_relative "../../rails_helper"

RSpec.describe "Nquery::Dashboards", type: :request do
  let(:root_collection) { Nquery::Collection.roots.first }
  let(:admin) { Nquery::User.find_by!(email: "admin@nquery.dev") }

  def sign_in_as(user)
    post "/login", params: { email: user.email, password: "password123" }
  end

  def sign_in_as_admin
    sign_in_as(admin)
  end

  describe "GET /dashboards" do
    before { sign_in_as_admin }

    it "returns success" do
      get "/dashboards"

      expect(response).to have_http_status(:ok)
    end

    it "lists dashboards" do
      get "/dashboards"

      expect(response.body).to include("Executive overview")
      expect(response.body).to include('href="/dashboards/')
    end

    it "highlights dashboards in the sidebar" do
      get "/dashboards"

      expect(response.body).to include('class="nq-nav-link active" href="/dashboards"')
      expect(response.body).to include('<span aria-current="page">Dashboards</span>')
    end

    it "does not expose a top-level new link" do
      get "/dashboards"

      expect(response.body).not_to include('href="/dashboards/new"')
    end

    context "when a dashboard is archived" do
      let!(:dashboard) do
        Nquery::Dashboard.create!(
          name: "Archived board",
          collection: root_collection,
          creator: admin
        )
      end

      before { dashboard.archive! }

      it "excludes it from the index" do
        get "/dashboards"

        expect(response.body).not_to include(dashboard.name)
      end
    end
  end

  describe "GET /dashboards/:id" do
    let!(:dashboard) do
      Nquery::Dashboard.create!(
        name: "Ops overview",
        collection: root_collection,
        creator: admin
      )
    end

    before { sign_in_as_admin }

    it "returns success" do
      get "/dashboards/#{dashboard.id}"

      expect(response).to have_http_status(:ok)
    end

    it "renders archive and remove actions" do
      get "/dashboards/#{dashboard.id}"

      expect(response.body).to include("Archive")
      expect(response.body).to include("Remove")
      expect(response.body).to include('class="nq-icon"')
      expect(response.body).to include("/dashboards/#{dashboard.id}/archive")
      expect(response.body).to include('data-turbo-confirm="Remove this dashboard?"')
    end

    it "renders chart card action menus" do
      dashboard = Nquery::Dashboard.find_by!(name: "Executive overview")
      chart = Nquery::Chart.find_by!(name: "Revenue by month")

      get "/dashboards/#{dashboard.id}"

      expect(response.body).to include('aria-label="Chart actions"')
      expect(response.body).to include('data-turbo-confirm="Archive this chart?"')
      expect(response.body).to include('data-turbo-confirm="Remove this chart?"')
      expect(response.body).to include("href=\"/dashboards/#{dashboard.id}/charts/#{chart.id}\"")
      expect(response.body).to include("href=\"/dashboards/#{dashboard.id}/charts/#{chart.id}/edit\"")
      expect(response.body).to include("/dashboards/#{dashboard.id}/charts/#{chart.id}/archive")
      expect(response.body).not_to include("href=\"/charts/#{chart.id}\"")
    end

    context "when the dashboard is archived" do
      before { dashboard.archive! }

      it "shows an archived notice" do
        get "/dashboards/#{dashboard.id}"

        expect(response.body).to include("This dashboard is archived.")
      end

      it "shows an unarchive action" do
        get "/dashboards/#{dashboard.id}"

        expect(response.body).to include("Unarchive")
        expect(response.body).to include("/dashboards/#{dashboard.id}/unarchive")
        expect(response.body).not_to include("/dashboards/#{dashboard.id}/archive\"")
      end
    end
  end

  describe "GET /collections/:collection_id/dashboards/new" do
    before { sign_in_as_admin }

    it "returns success" do
      get "/collections/#{root_collection.id}/dashboards/new"

      expect(response).to have_http_status(:ok)
    end

    it "renders the new dashboard form" do
      get "/collections/#{root_collection.id}/dashboards/new"

      expect(response.body).to include("New dashboard")
    end
  end

  describe "GET /dashboards/new" do
    before { sign_in_as_admin }

    it "is not found" do
      get "/dashboards/new"

      expect(response).to have_http_status(:not_found)
    end
  end

  describe "POST /collections/:collection_id/dashboards" do
    before { sign_in_as_admin }

    it "creates a dashboard" do
      expect {
        post "/collections/#{root_collection.id}/dashboards", params: {
          dashboard: { name: "Ops overview", description: "Daily ops" }
        }
      }.to change(Nquery::Dashboard, :count).by(1)

      dashboard = Nquery::Dashboard.find_by!(name: "Ops overview")
      expect(dashboard.collection).to eq(root_collection)
      expect(response).to redirect_to("/dashboards/#{dashboard.id}")
    end
  end

  describe "DELETE /dashboards/:id" do
    let!(:dashboard) do
      Nquery::Dashboard.create!(
        name: "Temporary board",
        collection: root_collection,
        creator: admin
      )
    end

    before { sign_in_as_admin }

    it "destroys the dashboard" do
      expect {
        delete "/dashboards/#{dashboard.id}"
      }.to change(Nquery::Dashboard, :count).by(-1)

      expect(response).to redirect_to("/dashboards")
      expect(flash[:notice]).to eq("Dashboard removed.")
    end
  end

  describe "PATCH /dashboards/:id/archive" do
    let!(:dashboard) do
      Nquery::Dashboard.create!(
        name: "Ops overview",
        collection: root_collection,
        creator: admin
      )
    end

    before { sign_in_as_admin }

    it "archives the dashboard" do
      patch "/dashboards/#{dashboard.id}/archive"

      expect(response).to redirect_to("/dashboards")
      expect(flash[:notice]).to eq("Dashboard archived.")
      expect(dashboard.reload.archived?).to be(true)
    end

    it "hides the dashboard from collection pages" do
      patch "/dashboards/#{dashboard.id}/archive"

      get "/collections/#{root_collection.id}"

      expect(response).to have_http_status(:ok)
      expect(response.body).not_to include(dashboard.name)
    end

    context "when the user lacks curate access" do
      let(:finance_group) { Nquery::Group.create!(name: "Finance", system_group: "custom") }
      let(:member) do
        Nquery::User.create!(email: "finance@example.com", password: "password123").tap do |user|
          Nquery::GroupMembership.create!(user: user, group: finance_group)
          user.ensure_all_users_membership!
        end
      end
      let(:restricted_collection) do
        Nquery::Collection.create!(
          name: "Finance",
          kind: "standard",
          parent: root_collection
        )
      end
      let!(:restricted_dashboard) do
        Nquery::CollectionPermission.create!(
          group: finance_group,
          collection: restricted_collection,
          access_level: "view"
        )

        Nquery::Dashboard.create!(
          name: "Finance dashboard",
          collection: restricted_collection,
          creator: member
        )
      end

      before { sign_in_as(member) }

      it "denies access" do
        patch "/dashboards/#{restricted_dashboard.id}/archive"

        expect(response).to redirect_to("/")
        expect(flash[:alert]).to include("permission")
        expect(restricted_dashboard.reload.archived?).to be(false)
      end
    end
  end

  describe "PATCH /dashboards/:id/unarchive" do
    let!(:dashboard) do
      Nquery::Dashboard.create!(
        name: "Ops overview",
        collection: root_collection,
        creator: admin
      )
    end

    before do
      dashboard.archive!
      sign_in_as_admin
    end

    it "unarchives the dashboard" do
      patch "/dashboards/#{dashboard.id}/unarchive"

      expect(response).to redirect_to("/dashboards/#{dashboard.id}")
      expect(flash[:notice]).to eq("Dashboard unarchived.")
      expect(dashboard.reload.archived?).to be(false)
    end
  end
end
