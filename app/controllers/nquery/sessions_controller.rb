# frozen_string_literal: true

module Nquery
  # Inherits Devise::SessionsController (→ host ApplicationController via Devise's
  # global parent_controller). Intentionally does NOT inherit Nquery::ApplicationController
  # so engine auth/onboarding callbacks are not applied to the sign-in flow.
  class SessionsController < Devise::SessionsController
    include Nquery::Engine.routes.url_helpers

    helper Nquery::ComponentsHelper
    helper Nquery::IconHelper

    layout "nquery/auth"

    private

    def after_sign_in_path_for(_resource)
      stored_location_for(:nquery_user) || root_path
    end

    def after_sign_out_path_for(_resource_or_scope)
      new_nquery_user_session_path
    end
  end
end
