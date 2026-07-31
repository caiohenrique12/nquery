# frozen_string_literal: true

require_relative "../../rails_helper"

RSpec.describe Nquery::Engine do
  it "loads the engine" do
    expect(described_class).to be < Rails::Engine
  end

  it "defaults authentication_provider to devise" do
    Nquery.reset_configuration!

    expect(Nquery.configuration.authentication_provider).to eq(:devise)
  end

  it "registers engine initializers" do
    names = described_class.initializers.map(&:name)
    expect(names).to include(
      "nquery.assets",
      "nquery.migrations",
      "nquery.mailer",
      "nquery.devise",
      "nquery.devise_mapping",
      "nquery.components"
    )
  end

  it "configures Devise mailer settings" do
    described_class.configure_devise!

    expect(Devise.mailer).to eq(Nquery::DeviseMailer)
    expect(Devise.parent_mailer).to eq("Nquery::ApplicationMailer")
  end

  it "executes conditional initializer branches" do
    assets_paths = []
    assets_precompile = []
    assets = Object.new
    assets.define_singleton_method(:paths) { assets_paths }
    assets.define_singleton_method(:precompile) { assets_precompile }
    assets.define_singleton_method(:precompile=) { |value| assets_precompile.replace(Array(value)) }

    importmap_paths = []
    importmap_sweepers = []
    importmap = Object.new
    importmap.define_singleton_method(:paths) { importmap_paths }
    importmap.define_singleton_method(:cache_sweepers) { importmap_sweepers }

    migrate_paths = []
    config = Object.new
    config.define_singleton_method(:assets) { assets }
    config.define_singleton_method(:importmap) { importmap }
    config.define_singleton_method(:paths) { { "db/migrate" => migrate_paths } }
    config.define_singleton_method(:respond_to?) { |method| %i[assets importmap].include?(method) }

    app = Object.new
    app.define_singleton_method(:config) { config }
    app.define_singleton_method(:root) { Pathname.new("/host/myapp") }
    app.define_singleton_method(:respond_to?) { |method| method == :importmap }

    stub_const("Sprockets", Module.new)

    described_class.initializers.find { |i| i.name == "nquery.assets" }.block.call(app)
    described_class.initializers.find { |i| i.name == "nquery.importmap" }.block.call(app)
    described_class.initializers.find { |i| i.name == "nquery.migrations" }.block.call(app)

    expect(assets_paths).not_to be_empty
    expect(importmap_paths).not_to be_empty
    expect(migrate_paths).not_to be_empty
  end

  it "registers rake tasks" do
    Rails.application.load_tasks

    expect(Rake::Task.task_defined?("nquery:seed")).to be(true)
    expect(Rake::Task.task_defined?("nquery:setup")).to be(true)
  end
end
