# frozen_string_literal: true

module Nquery
  module Admin
    class UsersController < BaseController
      def index
        @users = User.active.includes(:groups).order(:email)
      end

      def show
        @user = User.find(params[:id])
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
          render :new, status: :unprocessable_entity
        end
      end

      def edit
        @user = User.find(params[:id])
        @groups = Group.order(:name)
      end

      def update
        @user = User.find(params[:id])
        if @user.update(user_params)
          assign_groups(@user)
          redirect_to admin_users_path, notice: "User updated."
        else
          @groups = Group.order(:name)
          render :edit, status: :unprocessable_entity
        end
      end

      private

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
