# frozen_string_literal: true

require "openssl"
require "json"

module Nquery
  class EmbedTokenService
    class Error < StandardError; end

    def self.sign(resource_type:, resource_id:, params: {}, expires_at: 1.hour.from_now, creator: nil)
      token = generate_token
      payload = {
        token: token,
        resource_type: resource_type,
        resource_id: resource_id,
        params: params,
        exp: expires_at.to_i
      }
      data = Base64.urlsafe_encode64(payload.to_json)

      signature = OpenSSL::HMAC.hexdigest("SHA256", signing_key, data)
      signed = "#{data}.#{signature}"

      EmbedToken.create!(
        token: token,
        resource_type: resource_type,
        resource_id: resource_id,
        creator: creator,
        params: params,
        expires_at: expires_at,
        active: true
      )

      { token: token, signed_token: signed, expires_at: expires_at }
    end

    def self.verify(signed_token)
      data, signature = signed_token.to_s.split(".", 2)
      raise Error, "Invalid token format" unless data.present? && signature.present?

      expected_signature = OpenSSL::HMAC.hexdigest("SHA256", signing_key, data)
      unless ActiveSupport::SecurityUtils.secure_compare(expected_signature, signature)
        raise Error, "Invalid token signature"
      end

      payload = JSON.parse(Base64.urlsafe_decode64(data))
      raise Error, "Token expired" if payload["exp"].to_i <= Time.current.to_i

      record = EmbedToken.active.find_by(token: payload["token"])
      raise Error, "Token not found" unless record
      raise Error, "Token expired" if record.expired?
      raise Error, "Token mismatch" unless record.resource_type == payload["resource_type"] &&
                                           record.resource_id == payload["resource_id"].to_i

      {
        resource_type: record.resource_type,
        resource_id: record.resource_id,
        params: record.params
      }
    end

    def self.signed_token_for(record)
      payload = {
        token: record.token,
        resource_type: record.resource_type,
        resource_id: record.resource_id,
        params: record.params || {},
        exp: record.expires_at.to_i
      }
      data = Base64.urlsafe_encode64(payload.to_json)
      signature = OpenSSL::HMAC.hexdigest("SHA256", signing_key, data)
      "#{data}.#{signature}"
    end

    def self.generate_token
      SecureRandom.urlsafe_base64(24)
    end

    def self.signing_key
      Nquery.configuration.embed_signing_key
    end
  end
end
