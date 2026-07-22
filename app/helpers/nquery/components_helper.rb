# frozen_string_literal: true

module Nquery
  module ComponentsHelper
    def render_nquery_component(component, &block)
      component.render_in(self, &block)
    end

    def nq_flash_cards(flash: self.flash)
      render_nquery_component(FlashCardsComponent.new(flash: flash))
    end

    def nq_flash_card(message, type: :notice, **options)
      render_nquery_component(FlashCardComponent.new(message: message, type: type, **options))
    end

    def nq_card(title: nil, **options, &block)
      CardComponent.new(title: title, **options).render_in(self, &block)
    end

    def nq_card_table(columns:, **options, &block)
      CardTableComponent.new(columns: columns, **options).render_in(self, &block)
    end

    def nq_infinite_scroll(url:, **options, &block)
      InfiniteScrollComponent.new(url: url, **options).render_in(self, &block)
    end
  end
end
