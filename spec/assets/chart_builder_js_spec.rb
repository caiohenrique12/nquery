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

  it "updates the variable list from placeholders in the SQL" do
    expect(js).to include("function syncChartVariables")
    expect(js).to include("chartVariableParameters")
    expect(js).to include("data-chart-variables-target")
  end

  it "highlights the selected parameter in the SQL editor" do
    expect(js).to include("function highlightChartVariable")
    expect(js).to include("nq-sql-parameter")
    expect(js).to include("markText")
  end

  it "opens schema sidebar options when a parameter is added" do
    expect(js).to include("function selectChartVariable")
    expect(js).to include("function nextParameterName")
    expect(js).to include("selectAdded")
    expect(js).to include("chart_variable_options")
    expect(js).to include("replaceSelection")
  end

  it "delegates variable autosave from the chart builder root" do
    expect(js).to include('root.addEventListener("input"')
    expect(js).to include('root.addEventListener("change"')
    expect(js).to include('closest("#chart_variables")')
    expect(js).not_to include('getElementById("chart_variables")?.addEventListener')
  end

  it "posts variable defaults when running a query" do
    expect(js).to include("parameters: chartVariableParameters()")
  end

  it "posts query runs and schema loads to engine-provided URLs" do
    expect(js).to include("queryRunUrl")
    expect(js).to include("querySchemaUrl")
    expect(js).not_to include('fetch("/queries/run"')
    expect(js).not_to include("fetch(`/queries/schema")
  end
end
