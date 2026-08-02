# frozen_string_literal: true

module Nquery
  module Onboarding
    class ConfirmationsController < BaseController
      skip_before_action :ensure_onboarding_available!

      def show
        @user = find_confirmable_user
        redirect_to login_path, alert: "Invalid confirmation link." unless @user
      end

      def update
        @user = find_confirmable_user
        return redirect_to login_path, alert: "Invalid confirmation link." unless @user

        result = Onboarding::PasswordConfirmation.call(
          user: @user,
          password: confirmation_params[:password],
          password_confirmation: confirmation_params[:password_confirmation]
        )

        if result.success?
          sign_in_nquery_user(result.user)
          redirect_to root_path, notice: "Your account is ready. Welcome to nquery!"
        else
          render :show, status: :unprocessable_content
        end
      end

      private

      def find_confirmable_user
        token = params[:confirmation_token].to_s
        return if token.blank?

        user = User.find_by(confirmation_token: token, confirmed_at: nil)
        return if user.nil? || user.confirmation_expired?

        user
      end

      def confirmation_params
        params.require(:user).permit(:password, :password_confirmation)
      end
    end
  end
end
