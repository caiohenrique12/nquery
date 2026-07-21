# frozen_string_literal: true

module Nquery
  class SessionsController < ApplicationController
    skip_before_action :_authenticate!
    layout "nquery/auth"

    def new
      redirect_to root_path if current_nquery_user
    end

    def create
      user = User.active.find_by(email: params[:email]&.downcase)
      if user&.authenticate(params[:password])
        session[:nquery_user_id] = user.id
        redirect_to root_path, notice: "Signed in successfully."
      else
        flash.now[:alert] = "Invalid email or password."
        render :new, status: :unprocessable_entity
      end
    end

    def destroy
      session.delete(:nquery_user_id)
      redirect_to login_path, notice: "Signed out."
    end
  end
end
