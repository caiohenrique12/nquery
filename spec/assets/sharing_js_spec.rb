# frozen_string_literal: true

require_relative "../rails_helper"

RSpec.describe "Sharing JS" do
  let(:js_path) { Nquery::Engine.root.join("app/assets/builds/nquery/application.js") }
  let(:js) { File.read(js_path) }

  it "initializes copy buttons from data attributes" do
    expect(js).to include("function initCopyButtons")
    expect(js).to include("[data-copy-button]")
    expect(js).to include("navigator.clipboard.writeText")
    expect(js).to include("initCopyButtons()")
  end

  it "renders a chart error state from the payload" do
    expect(js).to include("data?.error")
    expect(js).to include("nq-chart-error")
    expect(js).to include("is-error")
  end
end
