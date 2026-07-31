# frozen_string_literal: true

ENV["RAILS_ENV"] = "test"

require_relative "../server/config/environment"
require "rspec/rails"
require "capybara/rspec"
require "selenium-webdriver"

Capybara.register_driver :headless_chrome do |app|
  options = Selenium::WebDriver::Chrome::Options.new
  options.add_argument("--headless=new")
  options.add_argument("--no-sandbox")
  options.add_argument("--disable-dev-shm-usage")
  Capybara::Selenium::Driver.new(app, browser: :chrome, options: options)
end

Capybara.javascript_driver = :headless_chrome
Capybara.default_driver = :rack_test
Capybara.app = Rails.application
Capybara.server = Rails.application

RSpec.configure do |config|
  config.use_transactional_fixtures = true
  config.infer_spec_type_from_file_location!
  config.filter_rails_from_backtrace!

  config.before(:each, type: :request) do
    host! "www.example.com"
  end

  config.after(:each) do
    Nquery.reset_configuration!
    Nquery.configure do |config|
      config.authentication_provider = :native
      config.mailer_sender = "noreply@nquery.dev"
    end
  end

  config.before(:each, type: :system) do
    driven_by :rack_test
  end

  config.before(:suite) do
    Nquery::Seeder.run!
  end

  config.include ActiveSupport::Testing::TimeHelpers
end
