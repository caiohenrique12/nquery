# frozen_string_literal: true

Rails.application.configure do
  config.secret_key_base = ENV.fetch("SECRET_KEY_BASE", "development_secret_key_base_for_local_only")
end
