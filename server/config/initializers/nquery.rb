# frozen_string_literal: true

Nquery.configure do |config|
  config.mailer_sender = "noreply@nquery.dev"
  config.public_sharing_enabled = true
  config.static_embedding_enabled = true
end
