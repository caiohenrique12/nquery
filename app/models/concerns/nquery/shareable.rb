# frozen_string_literal: true

module Nquery
  module Shareable
    extend ActiveSupport::Concern

    included do
      resource_class_name = name

      belongs_to :made_public_by, class_name: "Nquery::User", optional: true
      has_many :embed_tokens, -> { where(resource_type: resource_class_name) },
               class_name: "Nquery::EmbedToken", foreign_key: :resource_id, dependent: :destroy

      scope :publicly_shared, -> { where.not(public_uuid: nil) }
      scope :embedding_enabled, -> { where(enable_embedding: true) }

      validates :public_uuid, uniqueness: true, allow_nil: true
    end

    def publicly_shared?
      public_uuid.present?
    end

    def share_publicly!(user:)
      return self if publicly_shared?

      update!(
        public_uuid: SecureRandom.uuid,
        made_public_by: user,
        public_shared_at: Time.current
      )
      self
    end

    def unshare_publicly!
      update!(public_uuid: nil, made_public_by: nil, public_shared_at: nil)
    end

    def active_embed_token
      embed_tokens.active.order(created_at: :desc).first
    end
  end
end
