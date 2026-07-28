# frozen_string_literal: true

require "digest"

module Nquery
  module Encryption
    module_function

    def configure!(app)
      encryption = app.config.active_record.encryption
      return if encryption.primary_key.present?

      unless derive_keys_allowed?(app)
        warn_missing_keys(app)
        return
      end

      secret = app.secret_key_base
      encryption.primary_key = derived_key(secret, "primary")
      encryption.deterministic_key = derived_key(secret, "deterministic")
      encryption.key_derivation_salt = derived_key(secret, "salt")
      encryption.support_unencrypted_data = support_unencrypted_data if encryption.support_unencrypted_data.nil?
    end

    def derive_keys_allowed?(app)
      app.config.consider_all_requests_local
    end

    def support_unencrypted_data
      if ENV.key?("NQUERY_SUPPORT_UNENCRYPTED_DATA")
        return ActiveModel::Type::Boolean.new.cast(ENV.fetch("NQUERY_SUPPORT_UNENCRYPTED_DATA"))
      end

      true
    end

    def derived_key(secret, label)
      Digest::SHA256.hexdigest("nquery-#{label}-#{secret}")
    end

    def warn_missing_keys(app)
      return unless defined?(Rails) && Rails.logger

      Rails.logger.warn(
        "[nquery] Active Record encryption keys are not configured. " \
        "Set active_record_encryption in Rails credentials before deploying to production."
      )
    end
  end
end
