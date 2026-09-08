# frozen_string_literal: true

module Nquery
  module Boolean
    def self.cast(value)
      ActiveModel::Type::Boolean.new.cast(value)
    end
  end
end
