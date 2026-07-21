# frozen_string_literal: true

require_relative "../rails_helper"

RSpec.describe "Chart builder styles" do
  let(:css_path) { Nquery::Engine.root.join("app/assets/builds/nquery/application.css") }

  it "includes chart builder layout and output tab styles" do
    css = File.read(css_path)

    expect(css).to include(".nq-chart-builder-layout")
    expect(css).to include(".nq-output-panel.is-active")
    expect(css).to include(".nq-output-tab")
    expect(css).to include(".nq-chart-builder-results [hidden]")
  end
end
