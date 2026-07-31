# frozen_string_literal: true

module Nquery
  class Organization < ApplicationRecord
    has_one_attached :logo
    has_one_attached :cover_image

    validates :name, presence: true
  end
end
