# frozen_string_literal: true

module Nquery
  class Dashboard < ApplicationRecord
    belongs_to :collection, class_name: "Nquery::Collection", optional: true
    belongs_to :creator, class_name: "Nquery::User", optional: true
    has_many :dashboard_cards, class_name: "Nquery::DashboardCard", dependent: :destroy
    has_many :charts, through: :dashboard_cards, class_name: "Nquery::Chart"

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
  end
end
