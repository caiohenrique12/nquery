# frozen_string_literal: true

require "active_support/core_ext/integer/time"

Rails.application.configure do
  config.enable_reloading = true
  config.eager_load = false
  config.consider_all_requests_local = true
  config.server_timing = true
  config.cache_store = :memory_store
  config.active_support.deprecation = :log
  config.active_record.migration_error = :page_load
  config.active_record.verbose_query_logs = true
  config.active_storage.service = :local
  # Avoid SMTP to localhost (ECONNREFUSED) during onboarding / invites.
  # Mails are written under tmp/mail for inspection.
  config.action_mailer.delivery_method = :file
  config.action_mailer.file_settings = { location: Rails.root.join("tmp/mail") }
  config.action_mailer.raise_delivery_errors = true
  config.action_mailer.default_url_options = { host: "localhost", port: 3000 }
end
