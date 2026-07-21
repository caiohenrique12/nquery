# frozen_string_literal: true

module Nquery
  class CollectionPermission < ApplicationRecord
    ACCESS_LEVELS = %w[no_access view curate].freeze

    belongs_to :group, class_name: "Nquery::Group"
    belongs_to :collection, class_name: "Nquery::Collection"

    validates :access_level, inclusion: { in: ACCESS_LEVELS }
  end
end
