# frozen_string_literal: true

module Nquery
  class Engine < ::Rails::Engine
    isolate_namespace Nquery

    config.autoload_paths << root.join("app/components")
    config.eager_load_paths << root.join("app/components")

    config.generators do |g|
      g.test_framework :rspec
    end

    initializer "nquery.assets" do |app|
      next unless app.config.respond_to?(:assets)

      app.config.assets.paths << root.join("app/assets/builds").to_s
      app.config.assets.paths << root.join("app/assets/images").to_s

      if app.config.respond_to?(:assets) && defined?(::Sprockets)
        app.config.assets.precompile += %w[nquery_manifest.js]
      end
    end

    initializer "nquery.importmap", before: "importmap" do |app|
      if app.respond_to?(:importmap)
        app.config.importmap.paths << root.join("config/importmap.rb")
        app.config.importmap.cache_sweepers << root.join("app/assets/builds/nquery")
      end
    end

    initializer "nquery.migrations" do |app|
      next if app.root.to_s.start_with?(root.to_s)

      migration_path = root.join("db/migrate").to_s
      app.config.paths["db/migrate"] << migration_path unless app.config.paths["db/migrate"].include?(migration_path)
    end

    initializer "nquery.config" do
      Nquery.configure do |config|
        config.authentication_mode = ENV.fetch("NQUERY_AUTHENTICATION_MODE", "standalone").to_sym
      end
    end

    initializer "nquery.components" do
      ActiveSupport.on_load(:action_controller) do
        append_view_path Nquery::Engine.root.join("app/components")
      end
    end

    rake_tasks do
      load root.join("lib/tasks/nquery.rake")
    end
  end
end
