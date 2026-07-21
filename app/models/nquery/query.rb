# frozen_string_literal: true

module Nquery
  class Query < ApplicationRecord
    belongs_to :data_source, class_name: "Nquery::DataSource", optional: true
    belongs_to :creator, class_name: "Nquery::User", optional: true
    belongs_to :collection, class_name: "Nquery::Collection", optional: true
    has_one :chart, class_name: "Nquery::Chart", dependent: :destroy
    has_many :audits, class_name: "Nquery::Audit", dependent: :nullify

    validates :name, presence: true, on: :update

    before_validation :set_default_name, on: :create

    def set_default_name
      self.name ||= "Untitled query"
    end
  end
end
