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
  it "stores custom authentication and user resolution blocks" do
    config = described_class.new
    auth = proc { true }
    resolver = proc { |user| user }

    config.authenticate_with(&auth)
    config.resolve_nquery_user(&resolver)

    expect(config.authenticate).to eq(auth)
    expect(config.resolve_user).to eq(resolver)
  end
end

RSpec.describe Nquery::VERSION do
  it "defines the gem version" do
    expect(Nquery::VERSION).to eq("0.1.0")
  end
end
