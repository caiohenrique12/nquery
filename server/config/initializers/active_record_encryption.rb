# frozen_string_literal: true

Rails.application.configure do
  config.active_record.encryption.primary_key = ENV.fetch(
    "ACTIVE_RECORD_ENCRYPTION_PRIMARY_KEY",
    "nquery_test_primary_key_32chars_min!"
  )
  config.active_record.encryption.deterministic_key = ENV.fetch(
    "ACTIVE_RECORD_ENCRYPTION_DETERMINISTIC_KEY",
    "nquery_test_deterministic_key_32!"
  )
  config.active_record.encryption.key_derivation_salt = ENV.fetch(
    "ACTIVE_RECORD_ENCRYPTION_KEY_DERIVATION_SALT",
    "nquery_test_key_derivation_salt!"
  )
  config.active_record.encryption.support_unencrypted_data = true
end
