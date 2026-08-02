# frozen_string_literal: true

module Nquery
  module Onboarding
    class AdminsController < BaseController
      before_action :redirect_if_pending_confirmation!, only: %i[new create]
      before_action :require_organization!

      def new
        @user = User.new
      end

      def create
        @user = User.new(admin_params)
        if @user.valid?
          result = Onboarding::AdminProvisioner.call(@user)
          session[:onboarding_admin_email] = result.user.email
          if result.mail_delivered?
            redirect_to onboarding_congrats_path
          else
            redirect_to onboarding_congrats_path,
                        alert: "Your admin account was created, but the confirmation email could not be sent. Check your mailer settings."
          end
        else
          render :new, status: :unprocessable_content
        end
      end

      private

      def require_organization!
        return if session[:onboarding_organization_id].present? && Organization.exists?(id: session[:onboarding_organization_id])

        redirect_to new_onboarding_company_path, alert: "Please set up your company first."
      end

      def admin_params
        params.require(:user).permit(:email, :first_name, :last_name)
      end
    end
  end
end
