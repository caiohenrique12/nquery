# frozen_string_literal: true

require "rails_helper"

RSpec.describe Nquery::QueriesHelper, type: :helper do
  include Nquery::Engine.routes.url_helpers

  before do
    helper.extend Nquery::Engine.routes.url_helpers
  end

  describe "#query_editor_data" do
    it "includes the query editor controller and run URL" do
      expect(helper.query_editor_data).to eq(
        controller: "query-editor",
        query_run_url: run_queries_path
      )
    end
  end
end
