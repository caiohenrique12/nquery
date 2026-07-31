# frozen_string_literal: true

module Nquery
  module Onboarding
    class CongratsController < BaseController
      def show
        @email = session[:onboarding_admin_email]
        return if @email.present?
        return if Onboarding.pending_admin_confirmation?

        redirect_to new_onboarding_company_path, alert: "Please complete onboarding."
      end
    end
  end
end
