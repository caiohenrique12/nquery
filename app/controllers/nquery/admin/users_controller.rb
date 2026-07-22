# frozen_string_literal: true

module Nquery
  module Admin
    class UsersController < BaseController
      before_action :set_user, only: %i[show edit update deactivate destroy]

      def index
        @users = User.active.includes(:groups).order(:email)
      end

      def show
      end

      def new
        @user = User.new
        @groups = Group.order(:name)
      end

      def create
        @user = User.new(user_params)
        if @user.save
          assign_groups(@user)
          @user.ensure_all_users_membership!
          @user.ensure_personal_collection!
          redirect_to admin_users_path, notice: "User created."
        else
          @groups = Group.order(:name)
          render :new, status: :unprocessable_content
        end
      end

      def edit
        @groups = Group.order(:name)
      end

      def update
        if @user.update(user_params)
          assign_groups(@user)
          redirect_to admin_users_path, notice: "User updated."
        else
          @groups = Group.order(:name)
          render :edit, status: :unprocessable_content
        end
      end

      def deactivate
        return redirect_to admin_users_path, alert: "You cannot disable your own account." if @user == current_nquery_user

        @user.deactivate!
        redirect_to admin_users_path, notice: "#{@user.name} has been disabled."
      end

      def destroy
        return redirect_to admin_users_path, alert: "You cannot remove your own account." if @user == current_nquery_user

        name = @user.name
        @user.destroy!
        redirect_to admin_users_path, notice: "#{name} has been removed."
      end

      private

      def set_user
        @user = User.find(params[:id])
      end

      def user_params
        params.require(:user).permit(:email, :first_name, :last_name, :password, :password_confirmation)
      end

      def assign_groups(user)
        group_ids = params[:group_ids]&.reject(&:blank?) || []
        user.group_memberships.where.not(group_id: group_ids).destroy_all
        group_ids.each { |gid| user.group_memberships.find_or_create_by!(group_id: gid) }
        user.ensure_all_users_membership!
      end
    end
  end
end
