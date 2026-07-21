# frozen_string_literal: true

module Nquery
  module Admin
    class GroupsController < BaseController
      before_action :set_group, only: %i[show edit update add_member remove_member]

      def index
        @groups = Group.includes(:users).order(:name)
      end

      def show
        @available_users = User.active.where.not(id: @group.user_ids).order(:email)
      end

      def new
        @group = Group.new
      end

      def create
        @group = Group.new(group_params.merge(system_group: "custom"))
        if @group.save
          redirect_to admin_groups_path, notice: "Group created."
        else
          render :new, status: :unprocessable_entity
        end
      end

      def edit
      end

      def update
        if @group.update(group_params)
          redirect_to admin_groups_path, notice: "Group updated."
        else
          render :edit, status: :unprocessable_entity
        end
      end

      def add_member
        user = User.find(params[:user_id])
        @group.group_memberships.find_or_create_by!(user: user)
        redirect_to admin_group_path(@group), notice: "#{user.name} added to group."
      end

      def remove_member
        membership = @group.group_memberships.find_by!(user_id: params[:user_id])
        membership.destroy unless @group.system_group == "all_users"
        redirect_to admin_group_path(@group), notice: "Member removed."
      end

      private

      def set_group
        @group = Group.includes(:users).find(params[:id])
      end

      def group_params
        params.require(:group).permit(:name, :description)
      end
    end
  end
end
