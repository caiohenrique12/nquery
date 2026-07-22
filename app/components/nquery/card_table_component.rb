# frozen_string_literal: true

module Nquery
  class CardTableComponent < Component
    attr_reader :columns, :html_class, :table_class

    def initialize(columns:, class: nil, table_class: "nq-table")
      @columns = columns
      @html_class = binding.local_variable_get(:class)
      @table_class = table_class
    end

    def css_class
      classes = ["nq-card", "nq-card-table"]
      classes << html_class if html_class.present?
      classes.join(" ")
    end
  end
end
