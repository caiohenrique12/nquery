# frozen_string_literal: true

module Nquery
  class ApplicationRecord < ActiveRecord::Base
    self.abstract_class = true
  end
end
