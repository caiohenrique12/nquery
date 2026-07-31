# frozen_string_literal: true

module Nquery
  module Onboarding
    class PasswordConfirmation
      Result = Data.define(:success?, :user)

      def self.call(user:, password:, password_confirmation:)
        new(user:, password:, password_confirmation:).call
      end

      def initialize(user:, password:, password_confirmation:)
        @user = user
        @password = password
        @password_confirmation = password_confirmation
      end

      def call
        return failure unless user

        user.assign_attributes(password: password, password_confirmation: password_confirmation)
        return failure unless user.save

        user.confirm unless user.confirmed?
        latch_onboarding_completion!
        success
      end

      private

      attr_reader :user, :password, :password_confirmation

      def latch_onboarding_completion!
        Organization.first&.update!(onboarding_completed_at: Time.current)
      end

      def success
        Result.new(success?: true, user: user)
      end

      def failure
        Result.new(success?: false, user: user)
      end
    end
  end
end
