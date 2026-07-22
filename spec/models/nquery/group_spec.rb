# frozen_string_literal: true

require_relative "../../rails_helper"

RSpec.describe Nquery::Group do
  describe "#deletable?" do
    it "is true only for custom groups" do
      expect(described_class.new(system_group: "custom")).to be_deletable
      expect(described_class.new(system_group: "administrators")).not_to be_deletable
    end
  end
end
