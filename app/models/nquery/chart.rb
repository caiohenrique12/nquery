# frozen_string_literal: true

module Nquery
  class Chart < ApplicationRecord
    CHART_TYPES = %w[table number bar line area pie scatter].freeze

    belongs_to :query, class_name: "Nquery::Query", optional: true
    belongs_to :collection, class_name: "Nquery::Collection", optional: true
    belongs_to :creator, class_name: "Nquery::User", optional: true
    has_many :dashboard_cards, class_name: "Nquery::DashboardCard", dependent: :destroy
    has_many :embed_tokens, -> { where(resource_type: "Nquery::Chart") },
             class_name: "Nquery::EmbedToken", foreign_key: :resource_id, dependent: :destroy

    validates :name, presence: true

    def chart_type
      visualization["type"] || "bar"
    end
  end
end
