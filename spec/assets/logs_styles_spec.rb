# frozen_string_literal: true

require_relative "../rails_helper"

RSpec.describe "Logs table styles" do
  let(:css) { File.read(Nquery::Engine.root.join("app/assets/builds/nquery/application.css")) }

  it "includes a scrollable desktop table and stacked mobile rows" do
    expect(css).to include(".nq-logs-table")
    expect(css).to include("overflow-x: auto")
    expect(css).to include("attr(data-label)")
    expect(css).to include(".nq-logs-query")
    expect(css).to include(".nq-badge-success")
  end
end
