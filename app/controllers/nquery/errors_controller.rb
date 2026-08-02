# frozen_string_literal: true

module Nquery
  class ErrorsController < ApplicationController
    layout "nquery/auth"

    def not_found
      render status: :not_found
    end
  end
end
