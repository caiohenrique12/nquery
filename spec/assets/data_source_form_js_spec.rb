# frozen_string_literal: true

require_relative "../rails_helper"

RSpec.describe "Data source form JS" do
  let(:js_path) { Nquery::Engine.root.join("app/assets/builds/nquery/application.js") }
  let(:js) { File.read(js_path) }

  it "posts the form to the test connection endpoint" do
    expect(js).to include("dataSourceFormTestUrlValue")
    expect(js).to include("data-data-source-form-target='testButton'")
    expect(js).to include("data-data-source-form-target='testStatus'")
    expect(js).to include('method: "POST"')
    expect(js).to include("data_source_id")
    expect(js).to include('formData.delete("_method")')
    expect(js).to include("Connection successful.")
  end
end
