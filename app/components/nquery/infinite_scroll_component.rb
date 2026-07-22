# frozen_string_literal: true

module Nquery
  class InfiniteScrollComponent < Component
    attr_reader :url, :target, :html_class

    def initialize(url:, target: "items", class: nil)
      @url = url
      @target = target
      @html_class = binding.local_variable_get(:class)
    end

    def css_class
      classes = ["nq-infinite-scroll"]
      classes << html_class if html_class.present?
      classes.join(" ")
    end
  end
end
