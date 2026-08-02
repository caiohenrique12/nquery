# frozen_string_literal: true

module Nquery
  class ApplicationController < ActionController::Base
    include Devise::Controllers::Helpers
    include Nquery::AuthorizesCollection
    include Nquery::Breadcrumbs
    include Nquery::Engine.routes.url_helpers

    protect_from_forgery with: :exception
    layout "nquery/application"

    helper_method :current_nquery_user, :permission_resolver, :login_path, :logout_path

    before_action :redirect_to_onboarding, unless: :skip_onboarding_redirect?
    before_action :authenticate_nquery_user!, unless: :auth_exempt?
    before_action :set_current_user_context

    rescue_from StandardError, with: :render_internal_server_error
    rescue_from ActiveRecord::RecordNotFound, with: :render_not_found

    private

    def redirect_to_onboarding
      return if Onboarding.complete?

      redirect_to new_onboarding_company_path
    end

    def skip_onboarding_redirect?
      auth_exempt? || Onboarding.complete?
    end

    def auth_exempt?
      controller_path.in?(%w[
        nquery/sessions
        nquery/onboarding/companies
        nquery/onboarding/admins
        nquery/onboarding/congrats
        nquery/onboarding/confirmations
        nquery/embed/charts
        nquery/embed/dashboards
        nquery/errors
      ])
    end

    def render_not_found(_error = nil)
      render template: "nquery/errors/not_found", layout: "nquery/auth", status: :not_found
    end

    def render_internal_server_error(error)
      raise error if show_detailed_exceptions?

      Rails.logger.error("[nquery] #{error.class}: #{error.message}\n#{error.backtrace&.first(15)&.join("\n")}")
      render template: "nquery/errors/internal_server_error", layout: "nquery/auth", status: :internal_server_error
    end

    def show_detailed_exceptions?
      Rails.application.config.consider_all_requests_local
    end


    def login_path(**options)
      new_nquery_user_session_path(**options)
    end

    def logout_path(**options)
      destroy_nquery_user_session_path(**options)
    end

    def sign_in_nquery_user(user)
      sign_in(:nquery_user, user)
    end

    def set_current_user_context
      @permission_resolver = Permissions::Resolver.new(current_nquery_user) if current_nquery_user
    end

    def permission_resolver
      @permission_resolver ||= Permissions::Resolver.new(current_nquery_user)
    end

    def require_admin!
      redirect_to root_path, alert: "Admin access required." unless permission_resolver.admin?
    end
  end
end
