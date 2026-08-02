# frozen_string_literal: true

module Nquery
  class User < ApplicationRecord
    devise :database_authenticatable, :confirmable, :validatable,
           confirm_within: 1.hour

    has_many :group_memberships, class_name: "Nquery::GroupMembership", dependent: :destroy
    has_many :groups, through: :group_memberships, class_name: "Nquery::Group"
    has_many :queries, class_name: "Nquery::Query", foreign_key: :creator_id, inverse_of: :creator, dependent: :nullify
    has_many :charts, class_name: "Nquery::Chart", foreign_key: :creator_id, inverse_of: :creator, dependent: :nullify
    has_many :dashboards, class_name: "Nquery::Dashboard", foreign_key: :creator_id, inverse_of: :creator, dependent: :nullify
    has_many :audits, class_name: "Nquery::Audit", dependent: :nullify
    has_many :csv_uploads, class_name: "Nquery::CsvUpload", foreign_key: :creator_id, inverse_of: :creator, dependent: :nullify
    has_many :embed_tokens, class_name: "Nquery::EmbedToken", foreign_key: :creator_id, inverse_of: :creator, dependent: :nullify
    has_one :personal_collection, -> { where(kind: "personal") },
            class_name: "Nquery::Collection", foreign_key: :owner_id, inverse_of: :owner, dependent: :destroy

    validates :email, presence: true, uniqueness: true

    scope :active, -> { where(deactivated_at: nil) }

    # Set by #deliver_devise_notification so controllers can flash delivery failures.
    attr_accessor :last_devise_notification_delivered

    def name
      [first_name, last_name].compact_blank.join(" ").presence || email
    end

    def name_with_email
      "#{name} (#{email})"
    end

    def active?
      deactivated_at.nil?
    end

    def active_for_authentication?
      super && active?
    end

    def inactive_message
      active? ? super : :inactive
    end

    def deactivate!
      update!(deactivated_at: Time.current)
    end

    def admin?
      Permissions::Resolver.new(self).admin?
    end

    def ensure_all_users_membership!
      all_users = Group.find_by!(system_group: "all_users")
      group_memberships.find_or_create_by!(group: all_users)
    end

    def ensure_personal_collection!
      return personal_collection if personal_collection

      create_personal_collection!(name: "#{name}'s Personal Collection", kind: "personal")
    end

    def password_required?
      return false if new_record? && password.blank?

      super
    end

    def confirmation_expired?
      confirmation_period_expired?
    end

    # Returns false when delivery fails so callers can flash a warning instead of 500ing.
    def deliver_devise_notification(notification, *args)
      Nquery::DeviseMailer.send(notification, self, *args).deliver_now
      self.last_devise_notification_delivered = true
    rescue StandardError => error
      self.last_devise_notification_delivered = false
      Rails.logger.error(
        "[nquery] Failed to deliver Devise #{notification} to #{email}: #{error.class}: #{error.message}"
      )
      false
    end

    protected

    def send_devise_notification(notification, *args)
      deliver_devise_notification(notification, *args)
    end
  end
end
