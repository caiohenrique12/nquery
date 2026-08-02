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

  describe "authentication API" do
    it "does not expose authentication_provider" do
      expect(config).not_to respond_to(:authentication_provider)
      expect(config).not_to respond_to(:authentication_provider=)
    end

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
end

RSpec.describe Nquery::VERSION do
  it "defines the gem version" do
    expect(Nquery::VERSION).to eq("0.1.0")
  end
end
