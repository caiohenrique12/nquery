# frozen_string_literal: true

module Nquery
  class DashboardCard < ApplicationRecord
    belongs_to :dashboard, class_name: "Nquery::Dashboard"
    belongs_to :chart, class_name: "Nquery::Chart"
  end
end
