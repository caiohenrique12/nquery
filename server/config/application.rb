# frozen_string_literal: true

require_relative "boot"
require "rails/all"
Bundler.require(*Rails.groups)
require "nquery"

module NqueryServer
  class Application < Rails::Application
    config.load_defaults 8.0
    config.autoload_lib(ignore: %w[assets tasks])
    config.api_only = false
  end
end
