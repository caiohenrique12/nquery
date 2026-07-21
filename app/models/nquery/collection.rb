# frozen_string_literal: true

module Nquery
  class Collection < ApplicationRecord
    KINDS = %w[root personal standard].freeze

    belongs_to :parent, class_name: "Nquery::Collection", optional: true
    belongs_to :owner, class_name: "Nquery::User", optional: true
    has_many :children, class_name: "Nquery::Collection", foreign_key: :parent_id, dependent: :destroy
    has_many :collection_permissions, class_name: "Nquery::CollectionPermission", dependent: :destroy
    has_many :queries, class_name: "Nquery::Query", dependent: :nullify
    has_many :charts, class_name: "Nquery::Chart", dependent: :nullify
    has_many :dashboards, class_name: "Nquery::Dashboard", dependent: :nullify

    validates :name, presence: true
    validates :kind, inclusion: { in: KINDS }

    scope :roots, -> { where(kind: "root") }
    scope :shared, -> { where(kind: %w[root standard]) }
  end
end
