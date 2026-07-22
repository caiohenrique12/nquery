# frozen_string_literal: true

require "rails_helper"

RSpec.describe Nquery::HomeHelper, type: :helper do
  describe "#home_greeting" do
    it "greets in the morning" do
      travel_to Time.zone.parse("2026-07-22 09:00") do
        user = Struct.new(:first_name).new("Ada")
        helper.define_singleton_method(:current_nquery_user) { user }
        expect(helper.home_greeting).to eq("Good morning, Ada")
      end
    end

    it "greets in the afternoon" do
      travel_to Time.zone.parse("2026-07-22 14:00") do
        user = Struct.new(:first_name).new("Ada")
        helper.define_singleton_method(:current_nquery_user) { user }
        expect(helper.home_greeting).to eq("Good afternoon, Ada")
      end
    end

    it "falls back to 'there' when the user has no first name" do
      travel_to Time.zone.parse("2026-07-22 20:00") do
        user = Struct.new(:first_name).new(nil)
        helper.define_singleton_method(:current_nquery_user) { user }
        expect(helper.home_greeting).to eq("Good evening, there")
      end
    end
  end

  describe "#chart_type_label" do
    it "titleizes the chart type" do
      chart = Nquery::Chart.new(visualization: { "type" => "bar" })
      expect(helper.chart_type_label(chart)).to eq("Bar")
    end
  end
end
