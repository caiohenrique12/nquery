# frozen_string_literal: true

require_relative "../../rails_helper"

RSpec.describe Nquery::Boolean do
  describe ".cast" do
    context "when the value is truthy" do
      it "returns true for true" do
        expect(described_class.cast(true)).to be(true)
      end

      it "returns true for 'true'" do
        expect(described_class.cast("true")).to be(true)
      end

      it "returns true for '1'" do
        expect(described_class.cast("1")).to be(true)
      end
    end

    context "when the value is falsey" do
      it "returns false for false" do
        expect(described_class.cast(false)).to be(false)
      end

      it "returns false for 'false'" do
        expect(described_class.cast("false")).to be(false)
      end

      it "returns false for '0'" do
        expect(described_class.cast("0")).to be(false)
      end
    end

    context "when the value is blank" do
      it "returns nil for nil" do
        expect(described_class.cast(nil)).to be_nil
      end

      it "returns nil for an empty string" do
        expect(described_class.cast("")).to be_nil
      end
    end
  end
end
