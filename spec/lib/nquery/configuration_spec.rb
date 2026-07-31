# frozen_string_literal: true

require "nquery"
require "spec_helper"

RSpec.describe Nquery do
  describe ".reset_configuration!" do
    it "resets configuration to defaults" do
      Nquery.configure { |config| config.query_timeout = 99 }
      Nquery.reset_configuration!
      expect(Nquery.configuration.query_timeout).to eq(15)
    end
  end
end

RSpec.describe Nquery::Configuration do
  subject(:config) { described_class.new }

  describe "defaults" do
    it "uses devise as the authentication provider" do
      expect(config.authentication_provider).to eq(:devise)
    end

    it "declares identity-only data sources" do
      expect(config.data_sources).to eq(
        main: { adapter: :rails, name: "Application database" }
      )
    end

    it "sets the default data source key" do
      expect(config.default_data_source).to eq(:main)
    end

    it "starts with empty mail settings" do
      expect(config.mailer_sender).to be_nil
      expect(config.smtp).to eq({})
    end
  end

  describe "SSO API removal" do
    it "does not expose authentication_mode" do
      expect(config).not_to respond_to(:authentication_mode)
      expect(config).not_to respond_to(:authentication_mode=)
    end

    it "does not expose authenticate_with hooks" do
      expect(config).not_to respond_to(:authenticate_with)
      expect(config).not_to respond_to(:authenticate)
    end

    it "does not expose resolve_nquery_user hooks" do
      expect(config).not_to respond_to(:resolve_nquery_user)
      expect(config).not_to respond_to(:resolve_user)
    end

    it "does not expose current_user_method" do
      expect(config).not_to respond_to(:current_user_method)
      expect(config).not_to respond_to(:current_user_method=)
    end
  end

  describe "#devise_authentication?" do
    it "is true when provider is devise" do
      config.authentication_provider = :devise
      expect(config).to be_devise_authentication
    end

    it "is false when provider is native" do
      config.authentication_provider = :native
      expect(config).not_to be_devise_authentication
    end
  end

  describe "#native_authentication?" do
    it "is true when provider is native" do
      config.authentication_provider = :native
      expect(config).to be_native_authentication
    end

    it "is false when provider is devise" do
      config.authentication_provider = :devise
      expect(config).not_to be_native_authentication
    end
  end
end

RSpec.describe Nquery::VERSION do
  it "defines the gem version" do
    expect(Nquery::VERSION).to eq("0.1.0")
  end
end
