# frozen_string_literal: true

module Nquery
  class Audit < ApplicationRecord
    belongs_to :user, class_name: "Nquery::User", optional: true
    belongs_to :query, class_name: "Nquery::Query", optional: true

    scope :recent, -> { order(created_at: :desc) }
  end
end
