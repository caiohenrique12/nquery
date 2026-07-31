# frozen_string_literal: true

Rails.application.configure do
  config.enable_reloading = false
  config.eager_load = true
  config.consider_all_requests_local = true
  config.cache_store = :null_store
  config.active_support.deprecation = :stderr
  config.action_controller.allow_forgery_protection = false
  config.hosts = nil
  config.active_storage.service = :test
  config.action_mailer.delivery_method = :test
  config.action_mailer.perform_deliveries = true
  config.action_mailer.default_url_options = { host: "www.example.com" }
end
