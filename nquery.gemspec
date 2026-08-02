# frozen_string_literal: true

require_relative "lib/nquery/version"

Gem::Specification.new do |spec|
  spec.name        = "nquery"
  spec.version     = Nquery::VERSION
  spec.authors     = ["Nquery Contributors"]
  spec.email       = ["hello@nquery.dev"]
  spec.summary     = "SQL charts, dashboards, and data visualization for Rails"
  spec.description = "Mountable Rails engine for SQL charts, dashboards, and analytics."
  spec.homepage    = "https://github.com/nquery/nquery"
  spec.license     = "MIT"
  spec.required_ruby_version = ">= 3.2.0"

  spec.metadata["homepage_uri"] = spec.homepage
  spec.metadata["source_code_uri"] = spec.homepage

  spec.files = Dir.chdir(__dir__) do
    Dir["{app,config,db,lib}/**/*", "README.md", "LICENSE", "Rakefile", "nquery.gemspec"]
      .reject { |f| f.include?("/templates/") && f.end_with?(".tt") }
      .select { |f| File.file?(f) }
  end

  spec.add_dependency "rails", ">= 7.1", "< 9"
  spec.add_dependency "devise", "~> 4.9"
  spec.add_dependency "bcrypt", "~> 3.1"
  spec.add_dependency "csv"
  spec.add_dependency "importmap-rails"
  spec.add_dependency "turbo-rails"
  spec.add_dependency "stimulus-rails"
  spec.add_dependency "propshaft"

  spec.add_development_dependency "rspec-rails", "~> 7.0"
  spec.add_development_dependency "capybara", "~> 3.40"
  spec.add_development_dependency "selenium-webdriver", "~> 4.0"
  spec.add_development_dependency "sqlite3", "~> 2.0"
  spec.add_development_dependency "pg", "~> 1.5"
  spec.add_development_dependency "puma", "~> 6.0"
  spec.add_development_dependency "simplecov", "~> 0.22"
end
