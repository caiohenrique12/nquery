# frozen_string_literal: true

module Nquery
  class ApplicationController < ActionController::Base
    include Nquery::AuthorizesCollection
    include Nquery::Breadcrumbs
    include Nquery::Engine.routes.url_helpers

    protect_from_forgery with: :exception
    layout "nquery/application"

    helper_method :current_nquery_user, :permission_resolver

    before_action :redirect_to_onboarding, unless: :skip_onboarding_redirect?
    before_action :_authenticate!
    before_action :set_current_user_context

    private

    def _authenticate!
      return if auth_exempt?

      if Nquery.configuration.devise_authentication?
        authenticate_nquery_user!
      else
        default_authenticate!
      end
    end

    def default_authenticate!
      return if current_nquery_user

      redirect_to login_path, alert: "Please sign in to continue."
    end

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
      ])
    end

    def current_nquery_user
      @current_nquery_user ||= if Nquery.configuration.devise_authentication?
        warden.user(:nquery_user)
      else
        session_user
      end
    end

    def session_user
      return unless session[:nquery_user_id]

      User.active.find_by(id: session[:nquery_user_id])
    end

    def authenticate_nquery_user!
      return if current_nquery_user

      redirect_to login_path, alert: "Please sign in to continue."
    end

    def sign_in_nquery_user(user)
      if Nquery.configuration.devise_authentication?
        warden.set_user(user, scope: :nquery_user)
      else
        session[:nquery_user_id] = user.id
      end
    end

    def sign_out_nquery_user
      if Nquery.configuration.devise_authentication?
        warden.logout(:nquery_user)
      else
        session.delete(:nquery_user_id)
      end
    end

    def warden
      request.env["warden"]
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
