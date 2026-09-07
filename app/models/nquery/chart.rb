# frozen_string_literal: true

module Nquery
  class Chart < ApplicationRecord
    CHART_TYPES = %w[table number bar line area pie scatter].freeze

    include Shareable

    belongs_to :query, class_name: "Nquery::Query", optional: true
    belongs_to :collection, class_name: "Nquery::Collection", optional: true
    belongs_to :creator, class_name: "Nquery::User", optional: true
    has_many :dashboard_cards, class_name: "Nquery::DashboardCard", dependent: :destroy

    accepts_nested_attributes_for :query

    scope :active, -> { where(archived_at: nil) }
    scope :archived, -> { where.not(archived_at: nil) }

    validates :name, presence: true

    def archived?
      archived_at.present?
    end

    def archive!
      update!(archived_at: Time.current)
    end

    def unarchive!
      update!(archived_at: nil)
    end

    def chart_type
      visualization["type"] || "bar"
    end
  end
end
