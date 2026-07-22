# frozen_string_literal: true

require "rails_helper"

RSpec.describe Nquery::FlashCardComponent do
  describe "#initialize" do
    it "accepts a message and type" do
      component = described_class.new(message: "Saved.", type: :notice)

      expect(component.messages).to eq(["Saved."])
      expect(component.type).to eq(:notice)
      expect(component.css_class).to include("nq-flash-card-notice")
      expect(component.css_class).to include("nq-flash-card-toast")
      expect(component.toast?).to be(true)
      expect(component.auto_dismiss?).to be(true)
    end

    it "supports inline alerts that do not auto-dismiss" do
      component = described_class.new(message: "Archived.", type: :warning, toast: false)

      expect(component.css_class).to include("nq-flash-card-inline")
      expect(component.toast?).to be(false)
      expect(component.auto_dismiss?).to be(false)
    end

    it "accepts multiple messages" do
      component = described_class.new(messages: ["One", "Two"], type: :warning)

      expect(component.messages).to eq(["One", "Two"])
      expect(component.role).to eq("status")
    end

    it "requires a message" do
      expect { described_class.new(type: :alert) }.to raise_error(ArgumentError, "message is required")
    end
  end
end

RSpec.describe Nquery::FlashCardsComponent do
  it "builds cards from the flash hash" do
    flash = ActionDispatch::Flash::FlashHash.new
    flash[:notice] = "Done."
    flash[:alert] = "Failed."

    component = described_class.new(flash: flash)

    expect(component.cards.map(&:type)).to eq(%i[notice alert])
    expect(component.any?).to be(true)
  end
end
