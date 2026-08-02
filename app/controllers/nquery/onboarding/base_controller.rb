# frozen_string_literal: true

module Nquery
  module Onboarding
    class BaseController < ApplicationController
      skip_before_action :authenticate_nquery_user!
      skip_before_action :redirect_to_onboarding
      before_action :ensure_onboarding_available!

      layout "nquery/auth"

      private

      def ensure_onboarding_available!
        return unless Onboarding.complete?

        redirect_to login_path, alert: "Onboarding has already been completed."
      end

      def redirect_if_pending_confirmation!
        return unless Onboarding.pending_admin_confirmation?

        redirect_to onboarding_congrats_path, alert: "Please confirm your email to continue setup."
      end
    end
  end
end
