# frozen_string_literal: true

module Nquery
  class ErrorsController < ApplicationController
    layout "nquery/auth"

    def not_found
      render status: :not_found
    end

    def internal_server_error
      render status: :internal_server_error
    end
  end
end
