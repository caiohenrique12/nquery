# frozen_string_literal: true

require_relative "../../rails_helper"

RSpec.describe Nquery::ParameterValue do
  describe ".parse" do
    it "rejects an unknown type" do
      expect(described_class.parse("float", "1")).to eq(:invalid)
    end

    it "parses a datetime that includes a timezone" do
      expect(described_class.parse("datetime", "2026-08-01T15:30:00Z")).to eq(Time.iso8601("2026-08-01T15:30:00Z"))
    end

    it "rejects a datetime whose calendar date does not exist" do
      expect(described_class.parse("datetime", "2026-02-31T15:30:00Z")).to eq(:invalid)
    end

    it "rejects a datetime that is not an ISO timestamp" do
      expect(described_class.parse("datetime", "August 1")).to eq(:invalid)
    end
  end
end
