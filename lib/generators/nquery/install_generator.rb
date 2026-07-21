# frozen_string_literal: true

require "rails/generators/base"
require "rails/generators/migration"

module Nquery
  module Generators
    class InstallGenerator < Rails::Generators::Base
      include Rails::Generators::Migration
      source_root File.expand_path("templates", __dir__)

      desc "Install nquery: copies migration, initializer, and route mount snippet"

      def copy_migration
        migration_template "install.rb.tt", "db/migrate/install_nquery.rb", migration_version: migration_version
      end

      def copy_initializer
        template "nquery.rb.tt", "config/initializers/nquery.rb"
      end

      def show_route_snippet
        say "\nAdd to config/routes.rb:\n", :green
        say <<~ROUTE
          authenticate :user, ->(u) { u.admin? } do
            mount Nquery::Engine, at: "/nquery"
          end
        ROUTE
      end

      private

      def migration_version
        "[#{ActiveRecord::Migration.current_version}]"
      end
    end
  end
end
