# frozen_string_literal: true

module Nquery
  class CsvUpload < ApplicationRecord
    STATUSES = %w[pending processing completed failed].freeze

    belongs_to :creator, class_name: "Nquery::User", optional: true

    validates :status, inclusion: { in: STATUSES }
  end
end
