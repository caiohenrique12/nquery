# frozen_string_literal: true

require_relative "../../rails_helper"

RSpec.describe Nquery::Shareable do
  let(:admin) { Nquery::User.find_by!(email: "admin@nquery.dev") }
  let(:data_source) { Nquery::DataSource.find_by!(key: "main") }
  let(:root_collection) { Nquery::Collection.roots.first }
  let(:chart) do
    query = Nquery::Query.create!(
      name: "Shareable query",
      statement: "SELECT 1 AS value",
      data_source: data_source,
      creator: admin,
      collection: root_collection
    )
    Nquery::Chart.create!(
      name: "Shareable chart",
      query: query,
      collection: root_collection,
      creator: admin,
      visualization: { "type" => "table" }
    )
  end

  describe "#share_publicly!" do
    it "assigns a uuid and records the publisher" do
      chart.share_publicly!(user: admin)

      expect(chart).to be_publicly_shared
      expect(chart.public_uuid).to be_present
      expect(chart.made_public_by).to eq(admin)
      expect(chart.public_shared_at).to be_present
    end

    it "does not replace an existing uuid" do
      chart.share_publicly!(user: admin)
      original = chart.public_uuid

      chart.share_publicly!(user: admin)

      expect(chart.public_uuid).to eq(original)
    end
  end

  describe "#unshare_publicly!" do
    it "clears the public link" do
      chart.share_publicly!(user: admin)
      chart.unshare_publicly!

      expect(chart).not_to be_publicly_shared
      expect(chart.made_public_by).to be_nil
      expect(chart.public_shared_at).to be_nil
    end
  end

  describe "#active_embed_token" do
    it "returns the newest active token" do
      first = Nquery::EmbedTokenService.sign(resource_type: "Nquery::Chart", resource_id: chart.id, creator: admin)
      travel 1.second
      second = Nquery::EmbedTokenService.sign(resource_type: "Nquery::Chart", resource_id: chart.id, creator: admin)

      expect(chart.active_embed_token.token).to eq(second[:token])

      Nquery::EmbedTokenService.revoke!(Nquery::EmbedToken.find_by!(token: second[:token]))
      expect(chart.active_embed_token.token).to eq(first[:token])
    end
  end

  describe ".publicly_shared" do
    it "includes only resources with a public uuid" do
      chart.share_publicly!(user: admin)

      expect(Nquery::Chart.publicly_shared).to include(chart)
    end
  end
end
