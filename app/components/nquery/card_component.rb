# frozen_string_literal: true

module Nquery
  class CardComponent < Component
    attr_reader :title, :html_class

    def initialize(title: nil, class: nil)
      @title = title
      @html_class = binding.local_variable_get(:class)
    end

    def css_class
      classes = ["nq-card"]
      classes << html_class if html_class.present?
      classes.join(" ")
    end
  end
end
