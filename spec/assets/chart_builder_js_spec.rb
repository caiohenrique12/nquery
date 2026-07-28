# frozen_string_literal: true

require_relative "../rails_helper"

RSpec.describe "Chart builder JS" do
  let(:js_path) { Nquery::Engine.root.join("app/assets/builds/nquery/application.js") }
  let(:js) { File.read(js_path) }

  it "keeps visualization type when switching to the table output tab" do
    expect(js).to include("Table/Chart tabs are preview modes only")
    expect(js).not_to match(/if \(tab === "table"\) \{\s*if \(typeField\) typeField\.value = "table"/)
  end

  it "seeds saved chart results into the builder on edit" do
    expect(js).to include("applyResult")
    expect(js).to include("root.dataset.initialResult")
    expect(js).to include("initialResult.error")
  end

  it "renders dashboard previews for saved chart types beyond pie/bar" do
    expect(js).to include("buildPreviewChartConfig")
    expect(js).to include('type === "number"')
    expect(js).to include('el.classList.add("is-number")')
    expect(js).to include('type === "scatter"')
    expect(js).to include('fill: type === "area"')
  end
end
