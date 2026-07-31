# frozen_string_literal: true

require "devise"

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

    initializer "nquery.schema_dumper" do
      ActiveSupport.on_load(:active_record) do
        ActiveRecord::SchemaDumper.ignore_tables |= Nquery::SampleData::Ecommerce::REQUIRED_TABLES
      end
    end

    initializer "nquery.encryption", before: "active_record_encryption" do |app|
      Nquery::Encryption.configure!(app)
    end

    initializer "nquery.filter_parameters" do |app|
      app.config.filter_parameters += %i[
        password
        password_confirmation
        connection_config
        username
        database
        database_path
        host
        port
        sslmode
      ]
    end

    initializer "nquery.mailer" do
      config.to_prepare do
        mailer_sender = Nquery.configuration.mailer_sender
        smtp_settings = Nquery.configuration.smtp&.deep_symbolize_keys

        [Nquery::ApplicationMailer, Nquery::DeviseMailer].each do |mailer_class|
          mailer_class.default from: mailer_sender if mailer_sender.present?
          mailer_class.smtp_settings = smtp_settings if smtp_settings.present?
        end
      end
    end

    def self.configure_devise!
      Devise.setup do |config|
        config.mailer = "Nquery::DeviseMailer"
        config.mailer_sender = Nquery.configuration.mailer_sender || "noreply@example.com"
        config.parent_mailer = "Nquery::ApplicationMailer"
      end
    end

    initializer "nquery.devise" do
      ActiveSupport.on_load(:devise) { Nquery::Engine.configure_devise! }
    end

    initializer "nquery.devise_mapping", after: :load_config_initializers do
      config.to_prepare do
        Devise.add_mapping(:nquery_user, class_name: "Nquery::User") unless Devise.mappings.key?(:nquery_user)
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
