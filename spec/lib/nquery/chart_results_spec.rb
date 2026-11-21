# frozen_string_literal: true

require_relative "../../rails_helper"

RSpec.describe Nquery::ChartResults do
  subject(:host) do
    Class.new do
      include Nquery::ChartResults

      def parameter_hash(parameters)
        parameter_value_hash(parameters)
      end

      def invalid_parameter_names(parameters)
        parameter_invalid_names(parameters)
      end
    end.new
  end

  it "reads values from a hash" do
    values = { "start_date" => Date.new(2026, 8, 1) }

    expect(host.parameter_hash(values)).to eq(values)
  end

  it "treats a missing parameter object as empty" do
    expect(host.parameter_hash(nil)).to eq({})
    expect(host.invalid_parameter_names(nil)).to eq([])
  end
end
