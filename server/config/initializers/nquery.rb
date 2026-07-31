# frozen_string_literal: true

Nquery.configure do |config|
  config.authentication_provider = :native
  config.mailer_sender = "noreply@nquery.dev"
end
