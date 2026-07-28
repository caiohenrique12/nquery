# frozen_string_literal: true

require_relative "../../rails_helper"

RSpec.describe Nquery::Encryption do
  def build_app(consider_all_requests_local: true)
    Class.new do
      define_method(:initialize) do |local|
        @consider_all_requests_local = local
      end

      def secret_key_base
        "test-secret"
      end

      def config
        @config ||= ActiveSupport::OrderedOptions.new.tap do |options|
          options.consider_all_requests_local = @consider_all_requests_local
          options.active_record = ActiveSupport::OrderedOptions.new
          options.active_record.encryption = ActiveSupport::OrderedOptions.new
        end
      end
    end.new(consider_all_requests_local)
  end

  around do |example|
    original = ENV["NQUERY_SUPPORT_UNENCRYPTED_DATA"]
    ENV.delete("NQUERY_SUPPORT_UNENCRYPTED_DATA")
    example.run
  ensure
    if original.nil?
      ENV.delete("NQUERY_SUPPORT_UNENCRYPTED_DATA")
    else
      ENV["NQUERY_SUPPORT_UNENCRYPTED_DATA"] = original
    end
  end

  it "configures fallback encryption keys from secret_key_base in local apps" do
    app = build_app

    described_class.configure!(app)

    expect(app.config.active_record.encryption.primary_key).to be_present
    expect(app.config.active_record.encryption.deterministic_key).to be_present
    expect(app.config.active_record.encryption.key_derivation_salt).to be_present
    expect(app.config.active_record.encryption.support_unencrypted_data).to be(true)
  end

  it "does not derive keys when the host app is not local" do
    app = build_app(consider_all_requests_local: false)

    described_class.configure!(app)

    expect(app.config.active_record.encryption.primary_key).to be_nil
  end

  it "respects NQUERY_SUPPORT_UNENCRYPTED_DATA when deriving keys" do
    app = build_app
    ENV["NQUERY_SUPPORT_UNENCRYPTED_DATA"] = "false"

    described_class.configure!(app)

    expect(app.config.active_record.encryption.support_unencrypted_data).to be(false)
  end

  it "does not override support_unencrypted_data when already configured" do
    app = build_app
    app.config.active_record.encryption.support_unencrypted_data = false

    described_class.configure!(app)

    expect(app.config.active_record.encryption.support_unencrypted_data).to be(false)
  end
end
