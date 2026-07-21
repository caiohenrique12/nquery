# frozen_string_literal: true

Nquery.configure do |config|
  config.authentication_mode = ENV.fetch("NQUERY_AUTHENTICATION_MODE", "standalone").to_sym
end
