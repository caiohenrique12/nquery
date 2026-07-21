# frozen_string_literal: true

module Nquery
  class User < ApplicationRecord
    has_secure_password validations: false

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
    validates :password, length: { minimum: 8 }, if: -> { password.present? }

    scope :active, -> { where(deactivated_at: nil) }

    def name
      [first_name, last_name].compact_blank.join(" ").presence || email
    end

    def active?
      deactivated_at.nil?
    end

    def deactivate!
      update!(deactivated_at: Time.current)
    end

    def admin?
      Permissions::Resolver.new(self).admin?
    end

    def self.find_or_create_from_sso!(host_user)
      external_id = host_user.id.to_s
      find_or_create_by!(external_id: external_id) do |user|
        user.email = host_user.try(:email) || "#{external_id}@sso.local"
        user.first_name = host_user.try(:first_name) || host_user.try(:name)
      end.tap(&:ensure_all_users_membership!)
    end

    def ensure_all_users_membership!
      all_users = Group.find_by!(system_group: "all_users")
      group_memberships.find_or_create_by!(group: all_users)
    end

    def ensure_personal_collection!
      return personal_collection if personal_collection

      create_personal_collection!(name: "#{name}'s Personal Collection", kind: "personal")
    end
  end
end
