# frozen_string_literal: true

require_relative "../../rails_helper"

RSpec.describe Nquery::Seeder do
  describe ".run!" do
    let(:admin) { Nquery::User.find_by!(email: "admin@nquery.dev") }
    let(:chart) { Nquery::Chart.find_by!(name: "Revenue by month") }
    let(:dashboard) { Nquery::Dashboard.find_by!(name: "Executive overview") }

    it "is idempotent for demo charts and dashboards" do
      chart_count = Nquery::Chart.count
      dashboard_count = Nquery::Dashboard.count

      described_class.run!

      expect(Nquery::Chart.count).to eq(chart_count)
      expect(Nquery::Dashboard.count).to eq(dashboard_count)
    end

    it "ensures the demo chart has an active embed token after revoked tokens" do
      chart.embed_tokens.update_all(active: false)

      described_class.run!

      expect(chart.reload.active_embed_token).to be_present
      expect(chart.enable_embedding?).to be(true)
    end

    it "keeps the demo dashboard without a public link" do
      dashboard.share_publicly!(user: admin)

      described_class.run!

      expect(dashboard.reload).not_to be_publicly_shared
      expect(dashboard.enable_embedding?).to be(true)
    end
  end
end
