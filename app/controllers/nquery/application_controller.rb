# frozen_string_literal: true

module Nquery
  class ApplicationController < ActionController::Base
    include Nquery::AuthorizesCollection
    include Nquery::Breadcrumbs
    include Nquery::Engine.routes.url_helpers

    protect_from_forgery with: :exception
    layout "nquery/application"

    helper_method :current_nquery_user, :permission_resolver

    before_action :_authenticate!
    before_action :set_current_user_context

    private

    def _authenticate!
      if Nquery.configuration.authenticate
        instance_eval(&Nquery.configuration.authenticate)
      else
        default_authenticate!
      end
    end

    def default_authenticate!
      return if current_nquery_user
      return if auth_exempt?

      redirect_to login_path, alert: "Please sign in to continue."
    end

    def auth_exempt?
      controller_path.in?(%w[nquery/sessions nquery/registrations nquery/embed/charts nquery/embed/dashboards])
    end

    def current_nquery_user
      @current_nquery_user ||= resolve_current_user
    end

    def resolve_current_user
      if session[:nquery_user_id]
        return User.active.find_by(id: session[:nquery_user_id])
      end

      if Nquery.configuration.authentication_mode.in?(%i[sso hybrid])
        host_method = Nquery.configuration.current_user_method
        host_user = host_method.is_a?(Symbol) ? send(host_method) : instance_eval(&host_method)
        if host_user && Nquery.configuration.resolve_user
          return instance_eval { Nquery.configuration.resolve_user.call(host_user) }
        end
      end

      nil
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
