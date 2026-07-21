# frozen_string_literal: true

module Nquery
  class Dashboard < ApplicationRecord
    belongs_to :collection, class_name: "Nquery::Collection", optional: true
    belongs_to :creator, class_name: "Nquery::User", optional: true
    has_many :dashboard_cards, class_name: "Nquery::DashboardCard", dependent: :destroy
    has_many :charts, through: :dashboard_cards, class_name: "Nquery::Chart"
  end
end
