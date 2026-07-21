# frozen_string_literal: true

module Nquery
  class DataPermission < ApplicationRecord
    PERMISSION_TYPES = %w[view_data create_queries download_results manage_database].freeze

    belongs_to :group, class_name: "Nquery::Group"
    belongs_to :data_source, class_name: "Nquery::DataSource"

    validates :permission_type, inclusion: { in: PERMISSION_TYPES }
    validates :access_level, presence: true
  end
end
