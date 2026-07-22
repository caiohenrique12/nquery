# frozen_string_literal: true

require_relative "../../rails_helper"

RSpec.describe Nquery::EmbedToken do
  let(:admin) { Nquery::User.find_by!(email: "admin@nquery.dev") }
  let(:chart) { Nquery::Chart.find_by!(name: "Revenue by month") }

  describe "#resource" do
    it "loads the associated chart" do
      result = Nquery::EmbedTokenService.sign(
        resource_type: "Nquery::Chart",
        resource_id: chart.id,
        creator: admin
      )
      token = described_class.find_by!(token: result[:token])

      expect(token.resource).to eq(chart)
    end
  end

  describe "#expired?" do
    it "is true when expires_at is in the past" do
      token = described_class.new(expires_at: 1.hour.ago)
      expect(token).to be_expired
    end
  end
end
