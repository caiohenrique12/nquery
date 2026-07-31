# frozen_string_literal: true

module Nquery
  class SessionsController < ApplicationController
    skip_before_action :_authenticate!
    skip_before_action :redirect_to_onboarding
    layout "nquery/auth"

    def new
      redirect_to root_path if current_nquery_user
    end

    def create
      user = User.active.find_by(email: params[:email]&.downcase)
      if password_authenticated?(user, params[:password])
        sign_in_nquery_user(user)
        redirect_to root_path, notice: "Signed in successfully."
      else
        flash.now[:alert] = "Invalid email or password."
        render :new, status: :unprocessable_content
      end
    end

    def destroy
      sign_out_nquery_user
      redirect_to login_path, notice: "Signed out."
    end

    private

    def password_authenticated?(user, password)
      return false unless user&.valid_password?(password)

      if Nquery.configuration.devise_authentication?
        user.confirmed?
      else
        true
      end
    end
  end
end
