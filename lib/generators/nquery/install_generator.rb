# frozen_string_literal: true

require "rails/generators/base"

module Nquery
  module Generators
    class InstallGenerator < Rails::Generators::Base
      source_root File.expand_path("templates", __dir__)

      desc "Install nquery: copies initializer and prints setup instructions"

      def copy_initializer
        template "nquery.rb.tt", "config/initializers/nquery.rb"
      end

      def show_route_snippet
        say "\nNext steps:\n", :green
        say "  1. rails active_storage:install   # required for organization logo/cover uploads"
        say "  2. rails db:migrate               # engine migrations load from the gem automatically"
        say "  3. rails nquery:setup"
        say "  4. Add to config/routes.rb:\n"
        say <<~ROUTE
             mount Nquery::Engine, at: "/nquery"
        ROUTE
        say "  5. Set mailer_sender + smtp in config/initializers/nquery.rb"
        say "  6. Visit /nquery and complete the onboarding wizard\n"
      end
    end
  end
end
