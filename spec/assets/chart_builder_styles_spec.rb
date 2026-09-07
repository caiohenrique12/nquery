# frozen_string_literal: true

require_relative "../rails_helper"

RSpec.describe "Chart builder styles" do
  let(:css_path) { Nquery::Engine.root.join("app/assets/builds/nquery/application.css") }

  it "includes chart builder layout and output tab styles" do
    css = File.read(css_path)

    expect(css).to include(".nq-chart-builder-layout")
    expect(css).to include("align-items: stretch")
    expect(css).to include(".nq-chart-builder-schema .nq-schema-tree")
    expect(css).to include(".nq-chart-builder-name")
    expect(css).to include(".nq-workspace-tab")
    expect(css).to include(".nq-output-panel.is-active")
    expect(css).to include(".nq-output-tab")
    expect(css).to include(".nq-chart-builder-workspace [hidden]")
    expect(css).to include(".nq-schema-tree")
    expect(css).to include(".nq-schema-column-type")
    expect(css).to include(".nq-sql-editor-shell")
    expect(css).to include(".nq-chart-preview.is-number")
    expect(css).to include("align-items: center")
    expect(css).to include(".nq-sql-save-status")
    expect(css).to include('.nq-btn:disabled')
  end

  it "uses the same font stack on app and embed bodies" do
    css = File.read(css_path)

    expect(css).to include('--nq-font: -apple-system, BlinkMacSystemFont, "Segoe UI", Roboto, sans-serif')
    expect(css).to include("body.nq-body { margin: 0; font-family: var(--nq-font);")
    expect(css).to include(".nq-embed-body { margin: 0; padding: 1rem; background: #fff; font-family: var(--nq-font);")
  end
end
