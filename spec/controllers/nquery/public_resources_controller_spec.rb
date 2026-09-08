# frozen_string_literal: true

require_relative "../../rails_helper"

RSpec.describe Nquery::PublicResourcesController do
  describe ".apply_embed_rate_limit" do
    it "warns when Rails rate_limit is unavailable" do
      dummy = Class.new
      expect(Rails.logger).to receive(:warn).with(/not rate limited/)

      described_class.apply_embed_rate_limit(to: dummy)
    end
  end
end
