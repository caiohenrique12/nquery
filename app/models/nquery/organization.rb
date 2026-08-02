# frozen_string_literal: true

module Nquery
  class Organization < ApplicationRecord
    IMAGE_CONTENT_TYPES = %w[image/png image/jpeg image/jpg image/webp image/gif].freeze
    MAX_IMAGE_BYTE_SIZE = 5.megabytes

    has_one_attached :logo
    has_one_attached :cover_image

    validates :name, presence: true
    validate :acceptable_logo
    validate :acceptable_cover_image

    private

    def acceptable_logo
      validate_image_attachment(:logo)
    end

    def acceptable_cover_image
      validate_image_attachment(:cover_image)
    end

    def validate_image_attachment(name)
      attachment = public_send(name)
      return unless attachment.attached?

      unless attachment.blob.content_type.in?(IMAGE_CONTENT_TYPES)
        errors.add(name, "must be a PNG, JPEG, WebP, or GIF")
      end

      return unless attachment.blob.byte_size > MAX_IMAGE_BYTE_SIZE

      errors.add(name, "is too large (maximum is 5 MB)")
    end
  end
end
