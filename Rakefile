# frozen_string_literal: true

require "bundler/setup"
require "bundler/gem_tasks"

APP_RAKEFILE = File.expand_path("server/Rakefile", __dir__)
load "rails/tasks/engine.rake" if File.exist?(APP_RAKEFILE)

Dir.glob("lib/tasks/**/*.rake").each { |r| load r }
