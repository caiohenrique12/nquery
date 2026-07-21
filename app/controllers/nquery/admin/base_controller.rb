# frozen_string_literal: true

module Nquery
  module Admin
    class BaseController < ApplicationController
      before_action :require_admin!
    end
  end
end
