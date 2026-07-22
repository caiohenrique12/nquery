# frozen_string_literal: true

require "rails_helper"

RSpec.describe Nquery::CardComponent do
  it "builds css classes with an optional custom class" do
    component = described_class.new(title: "Users", class: "extra")

    expect(component.title).to eq("Users")
    expect(component.css_class).to eq("nq-card extra")
  end

  it "omits the custom class when blank" do
    component = described_class.new(title: "Users")

    expect(component.css_class).to eq("nq-card")
  end
end

RSpec.describe Nquery::InfiniteScrollComponent do
  it "exposes url, target, and css_class" do
    component = described_class.new(url: "/items", target: "rows", class: "mt-4")

    expect(component.url).to eq("/items")
    expect(component.target).to eq("rows")
    expect(component.css_class).to eq("nq-infinite-scroll mt-4")
  end
end

RSpec.describe Nquery::Component do
  it "delegates class-level render_in to an instance" do
    component = instance_double(Nquery::FlashCardComponent)
    view = ActionView::Base.new(ActionView::LookupContext.new([]), {}, nil)
    allow(Nquery::FlashCardComponent).to receive(:new).and_return(component)
    allow(component).to receive(:render_in).with(view).and_return("rendered")

    expect(Nquery::FlashCardComponent.render_in(view, message: "Hi", type: :notice)).to eq("rendered")
  end
end
