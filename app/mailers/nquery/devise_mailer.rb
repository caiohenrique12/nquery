# frozen_string_literal: true

module Nquery
  class DeviseMailer < Devise::Mailer
    include Nquery::Engine.routes.url_helpers

    default template_path: "nquery/devise_mailer"
  end
end
