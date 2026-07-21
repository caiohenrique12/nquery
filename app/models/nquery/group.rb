# frozen_string_literal: true

module Nquery
  class Group < ApplicationRecord
    SYSTEM_GROUPS = %w[administrators all_users custom].freeze

    has_many :group_memberships, class_name: "Nquery::GroupMembership", dependent: :destroy
    has_many :users, through: :group_memberships, class_name: "Nquery::User"
    has_many :data_permissions, class_name: "Nquery::DataPermission", dependent: :destroy
    has_many :collection_permissions, class_name: "Nquery::CollectionPermission", dependent: :destroy
    has_many :application_permissions, class_name: "Nquery::ApplicationPermission", dependent: :destroy

    validates :name, presence: true
    validates :system_group, inclusion: { in: SYSTEM_GROUPS }

    scope :custom, -> { where(system_group: "custom") }
    scope :system, -> { where.not(system_group: "custom") }

    def system?
      system_group != "custom"
    end

    def deletable?
      system_group == "custom"
    end
  end
end
