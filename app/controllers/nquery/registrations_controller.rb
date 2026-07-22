# frozen_string_literal: true

module Nquery
  class RegistrationsController < ApplicationController
    skip_before_action :_authenticate!
    layout "nquery/auth"

    def new
      redirect_to root_path if current_nquery_user
      @user = User.new
    end

    def create
      @user = User.new(registration_params)
      if @user.save
        @user.ensure_all_users_membership!
        @user.ensure_personal_collection!
        session[:nquery_user_id] = @user.id
        redirect_to root_path, notice: "Welcome to nquery!"
      else
        render :new, status: :unprocessable_content
      end
    end

    private

    def registration_params
      params.require(:user).permit(:email, :first_name, :last_name, :password, :password_confirmation)
    end
  end
end
