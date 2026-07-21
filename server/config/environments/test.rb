# frozen_string_literal: true

Rails.application.configure do
  config.enable_reloading = false
  config.eager_load = true
  config.consider_all_requests_local = true
  config.cache_store = :null_store
  config.active_support.deprecation = :stderr
  config.action_controller.allow_forgery_protection = false
  config.hosts = nil
end
