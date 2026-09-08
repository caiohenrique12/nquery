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

  it "does not show the global button loader on copy buttons" do
    expect(js).to include('button.hasAttribute("data-copy-button")')
  end

  it "renders a chart error state from the payload" do
    expect(js).to include("data?.error")
    expect(js).to include("nq-chart-error")
    expect(js).to include("is-error")
  end

  it "applies the project font stack to Chart.js defaults" do
    expect(js).to include("function applyChartFontDefaults")
    expect(js).to include('-apple-system, BlinkMacSystemFont, "Segoe UI", Roboto, sans-serif')
    expect(js).to include("Chart.defaults.font.family")
    expect(js).to include("applyChartFontDefaults()")
  end

  it "escapes number chart values before injecting HTML" do
    preview_js = File.read(Nquery::Engine.root.join("app/javascript/nquery/controllers/chart_preview_controller.js"))

    expect(js).to include('nq-number-display">${escapeHtml(value)}')
    expect(js).not_to match(/nq-number-display">\$\{value\}/)
    expect(preview_js).to include('nq-number-display">${escapeHtml(value)}')
    expect(preview_js).not_to match(/nq-number-display">\$\{value\}/)
  end
end
