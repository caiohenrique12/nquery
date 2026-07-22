# frozen_string_literal: true

require_relative "../../rails_helper"

RSpec.describe "Collection parent authorization", type: :request do
  let(:admin) { Nquery::User.find_by!(email: "admin@nquery.dev") }
  let(:root_collection) { Nquery::Collection.roots.first }

  def sign_in_as_admin
    post "/login", params: { email: admin.email, password: "password123" }
  end

  it "authorizes the target parent when updating a collection" do
    parent = Nquery::Collection.create!(name: "Target parent", kind: "standard", parent: root_collection)
    collection = Nquery::Collection.create!(name: "Movable", kind: "standard", parent: root_collection)
    sign_in_as_admin

    patch "/collections/#{collection.id}", params: { collection: { name: collection.name, parent_id: parent.id } }

    expect(response).to redirect_to("/collections/#{collection.id}")
    expect(collection.reload.parent).to eq(parent)
  end
end
