# frozen_string_literal: true

module Nquery
  class FlashCardsComponent < Component
    def initialize(flash:)
      @flash = flash
    end

    def cards
      [].tap do |list|
        list << FlashCardComponent.new(message: @flash[:notice], type: :notice) if @flash[:notice].present?
        list << FlashCardComponent.new(message: @flash[:alert], type: :alert) if @flash[:alert].present?
      end
    end

    def any?
      cards.any?
    end
  end
end
