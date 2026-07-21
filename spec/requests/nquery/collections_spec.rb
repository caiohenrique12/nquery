# frozen_string_literal: true

require_relative "../../rails_helper"

RSpec.describe "Nquery::Collections", type: :request do
  let(:root_collection) { Nquery::Collection.roots.first }

  def sign_in_as_admin
    post "/login", params: { email: "admin@nquery.dev", password: "password123" }
  end

  describe "GET /collections" do
    before { sign_in_as_admin }

    it "returns success" do
      get "/collections"

      expect(response).to have_http_status(:ok)
    end

    it "lists collections" do
      get "/collections"

      expect(response.body).to include("Our analytics")
      expect(response.body).to include('href="/collections/new"')
      expect(response.body).to include('class="nq-nav-link active" href="/collections"')
    end

    it "renders archive actions for non-root collections" do
      collection = Nquery::Collection.create!(name: "Marketing", kind: "standard", parent: root_collection)
      get "/collections"

      expect(response.body).to include("/collections/#{collection.id}/archive")
      expect(response.body).to include("Archive")
    end
  end

  describe "GET /collections/:id" do
    before { sign_in_as_admin }

    it "shows dashboards as cards with charts and actions" do
      dashboard = Nquery::Dashboard.find_by!(name: "Executive overview")
      chart = Nquery::Chart.find_by!(name: "Revenue by month")

      get "/collections/#{root_collection.id}"

      expect(response).to have_http_status(:ok)
      expect(response.body).to include("Executive overview")
      expect(response.body).to include("Revenue by month")
      expect(response.body).to include("nq-dashboard-summary-card")
      expect(response.body).to include("Created by Admin User")
      expect(response.body).to include("Archive")
      expect(response.body).to include("Remove")
      expect(response.body).to include("Top-level collection")
      expect(response.body).to include("href=\"/dashboards/#{dashboard.id}/charts/#{chart.id}\"")
      expect(response.body).to include("/dashboards/#{dashboard.id}/charts/#{chart.id}/archive")
      expect(response.body).to include('data-turbo-confirm="Archive this chart?"')
      expect(response.body).to include('data-turbo-confirm="Remove this chart?"')
      expect(response.body).to include('aria-label="Archive chart"')
      expect(response.body).to include('aria-label="Remove chart"')
      expect(response.body).not_to include('aria-label="Chart actions"')
      expect(response.body).not_to include("href=\"/charts/#{chart.id}\"")
    end

    context "when the collection is archived" do
      let(:collection) { Nquery::Collection.create!(name: "Archived folder", kind: "standard", parent: root_collection) }

      before { collection.archive! }

      it "shows an archived notice" do
        get "/collections/#{collection.id}"

        expect(response).to have_http_status(:ok)
        expect(response.body).to include("This collection is archived.")
      end

      it "shows an unarchive action" do
        get "/collections/#{collection.id}"

        expect(response.body).to include("Unarchive")
        expect(response.body).to include("/collections/#{collection.id}/unarchive")
      end
    end

    it "links to nested new dashboard" do
      get "/collections/#{root_collection.id}"

      expect(response.body).to include("href=\"/collections/#{root_collection.id}/dashboards/new\"")
      expect(response.body).not_to include("collection_id=#{root_collection.id}")
    end

    it "links to nested new collection" do
      get "/collections/#{root_collection.id}"

      expect(response.body).to include("href=\"/collections/#{root_collection.id}/collections/new\"")
    end

    context "when the collection is empty" do
      let(:personal_collection) { Nquery::User.find_by!(email: "admin@nquery.dev").personal_collection }

      it "shows an empty state" do
        get "/collections/#{personal_collection.id}"

        expect(response).to have_http_status(:ok)
        expect(response.body).to include("This collection is empty")
        expect(response.body).to include("Personal collection")
      end
    end
  end

  describe "GET /collections/new" do
    before { sign_in_as_admin }

    it "returns success" do
      get "/collections/new"

      expect(response).to have_http_status(:ok)
    end
  end

  describe "POST /collections" do
    before { sign_in_as_admin }

    it "creates a collection" do
      expect {
        post "/collections", params: {
          collection: { name: "Marketing", parent_id: root_collection.id }
        }
      }.to change(Nquery::Collection, :count).by(1)

      collection = Nquery::Collection.find_by!(name: "Marketing")
      expect(collection.kind).to eq("standard")
      expect(response).to redirect_to("/collections/#{collection.id}")
    end
  end

  describe "POST /collections/:collection_id/collections" do
    before { sign_in_as_admin }

    it "creates a subcollection" do
      expect {
        post "/collections/#{root_collection.id}/collections", params: {
          collection: { name: "Marketing" }
        }
      }.to change(Nquery::Collection, :count).by(1)

      collection = Nquery::Collection.find_by!(name: "Marketing")
      expect(collection.parent).to eq(root_collection)
      expect(response).to redirect_to("/collections/#{collection.id}")
    end
  end

  describe "PATCH /collections/:id" do
    before { sign_in_as_admin }

    it "updates a collection" do
      collection = Nquery::Collection.create!(name: "Sales", kind: "standard", parent: root_collection)

      patch "/collections/#{collection.id}", params: { collection: { name: "Revenue ops" } }

      expect(response).to redirect_to("/collections/#{collection.id}")
      expect(collection.reload.name).to eq("Revenue ops")
    end
  end

  describe "DELETE /collections/:id" do
    before { sign_in_as_admin }

    it "destroys a collection" do
      collection = Nquery::Collection.create!(name: "Temporary", kind: "standard", parent: root_collection)

      expect {
        delete "/collections/#{collection.id}"
      }.to change(Nquery::Collection, :count).by(-1)

      expect(response).to redirect_to("/collections")
    end
  end

  describe "PATCH /collections/:id/archive" do
    before { sign_in_as_admin }

    let(:collection) { Nquery::Collection.create!(name: "Marketing", kind: "standard", parent: root_collection) }

    it "archives the collection" do
      patch "/collections/#{collection.id}/archive"

      expect(response).to redirect_to("/collections")
      expect(flash[:notice]).to eq("Collection archived.")
      expect(collection.reload.archived?).to be(true)
    end

    it "prevents archiving root collections" do
      patch "/collections/#{root_collection.id}/archive"

      expect(response).to redirect_to("/collections")
      expect(flash[:alert]).to eq("Root collections cannot be archived.")
      expect(root_collection.reload.archived?).to be(false)
    end
  end

  describe "PATCH /collections/:id/unarchive" do
    before { sign_in_as_admin }

    let(:collection) do
      Nquery::Collection.create!(name: "Marketing", kind: "standard", parent: root_collection).tap(&:archive!)
    end

    it "unarchives the collection" do
      patch "/collections/#{collection.id}/unarchive"

      expect(response).to redirect_to("/collections/#{collection.id}")
      expect(flash[:notice]).to eq("Collection unarchived.")
      expect(collection.reload.archived?).to be(false)
    end
  end
end
