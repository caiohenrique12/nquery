# frozen_string_literal: true

module Nquery
  class ApplicationPermission < ApplicationRecord
    FEATURES = %w[settings monitoring subscriptions].freeze

    belongs_to :group, class_name: "Nquery::Group"

    validates :feature, inclusion: { in: FEATURES }
    validates :access_level, inclusion: { in: %w[yes no] }
  end
end
