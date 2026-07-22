# frozen_string_literal: true

require "rails_helper"

RSpec.describe Nquery::ComponentsHelper, type: :helper do
  describe "#nq_card" do
    it "renders a card component" do
      expect(Nquery::CardComponent).to receive(:new).with(title: "Users").and_call_original
      helper.nq_card(title: "Users") { "body" }
    end
  end

  describe "#nq_infinite_scroll" do
    it "renders an infinite scroll component" do
      component = instance_double(Nquery::InfiniteScrollComponent, render_in: "scroll")
      allow(Nquery::InfiniteScrollComponent).to receive(:new).and_return(component)

      expect(helper.nq_infinite_scroll(url: "/items")).to eq("scroll")
    end
  end
end
