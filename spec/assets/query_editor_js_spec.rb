# frozen_string_literal: true

require_relative "../rails_helper"

RSpec.describe "Query editor JS" do
  let(:js_path) { Nquery::Engine.root.join("app/javascript/nquery/controllers/query_editor_controller.js") }
  let(:js) { File.read(js_path) }

  it "posts query runs and schema loads to engine-provided URLs" do
    expect(js).to include("this.element.dataset.queryRunUrl")
    expect(js).to include("this.element.dataset.querySchemaUrl")
    expect(js).not_to include('fetch("/queries/run"')
    expect(js).not_to include("fetch(`/queries/schema")
  end
end
