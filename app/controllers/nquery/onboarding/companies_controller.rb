# frozen_string_literal: true

module Nquery
  module Onboarding
    class CompaniesController < BaseController
      before_action :redirect_if_pending_confirmation!, only: %i[new create]

      def new
        @organization = Organization.new
      end

      def create
        @organization = Organization.first_or_initialize
        @organization.assign_attributes(organization_params)
        if @organization.save
          session[:onboarding_organization_id] = @organization.id
          redirect_to new_onboarding_admin_path
        else
          render :new, status: :unprocessable_content
        end
      end

      private

      def organization_params
        params.require(:organization).permit(:name, :website, :logo, :cover_image)
      end
    end
  end
end
