# frozen_string_literal: true

module Nquery
  module Onboarding
    class AdminProvisioner
      def self.call(user)
        new(user).call
      end

      def initialize(user)
        @user = user
      end

      def call
        ActiveRecord::Base.transaction do
          @user.save!
          administrators_group.group_memberships.find_or_create_by!(user: @user)
          @user.ensure_all_users_membership!
          @user.ensure_personal_collection!
        end

        @user
      end

      private

      def administrators_group
        Group.find_by!(system_group: "administrators")
      end
    end
  end
end
