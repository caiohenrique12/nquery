# frozen_string_literal: true

module Nquery
  class EmbedToken < ApplicationRecord
    belongs_to :creator, class_name: "Nquery::User", optional: true

    validates :token, presence: true, uniqueness: true
    validates :resource_type, presence: true
    validates :resource_id, presence: true

    scope :active, -> { where(active: true).where("expires_at IS NULL OR expires_at > ?", Time.current) }

    def resource
      resource_type.constantize.find_by(id: resource_id)
    end

    def expired?
      expires_at.present? && expires_at <= Time.current
    end
  end
end
