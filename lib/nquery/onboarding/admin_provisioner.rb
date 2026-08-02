# frozen_string_literal: true

module Nquery
  module Onboarding
    class AdminProvisioner
      Result = Data.define(:user, :mail_delivered?)

      def self.call(user)
        new(user).call
      end

      def initialize(user)
        @user = user
      end

      def call
        @user.skip_confirmation_notification!

        ActiveRecord::Base.transaction do
          @user.save!
          administrators_group.group_memberships.find_or_create_by!(user: @user)
          @user.ensure_all_users_membership!
          @user.ensure_personal_collection!
        end

        Result.new(user: @user, mail_delivered?: deliver_confirmation_email)
      end

      private

      def deliver_confirmation_email
        @user.send_confirmation_instructions != false
      end

      def administrators_group
        Group.find_by!(system_group: "administrators")
      end
    end
  end
end
