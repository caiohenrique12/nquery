# frozen_string_literal: true

require_relative "../rails_helper"

RSpec.describe "Sidebar toggle assets" do
  let(:css) { File.read(Nquery::Engine.root.join("app/assets/builds/nquery/application.css")) }
  let(:js) { File.read(Nquery::Engine.root.join("app/assets/builds/nquery/application.js")) }

  it "slides the sidebar closed and open" do
    expect(css).to include(".nq-sidebar-toggle")
    expect(css).to include(".is-sidebar-collapsed .nq-sidebar")
    expect(css).to include(".is-sidebar-open .nq-sidebar")
    expect(js).to include("function initSidebarToggle")
    expect(js).to include("is-sidebar-collapsed")
    expect(js).to include("is-sidebar-open")
    expect(js).to include("initSidebarToggle()")
  end
end
