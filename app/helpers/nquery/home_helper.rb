# frozen_string_literal: true

module Nquery
  module HomeHelper
    def home_greeting
      hour = Time.zone.now.hour
      salutation = if hour < 12
                     "Good morning"
                   elsif hour < 18
                     "Good afternoon"
                   else
                     "Good evening"
                   end

      name = current_nquery_user&.first_name.presence || "there"
      "#{salutation}, #{name}"
    end

    def chart_type_label(chart)
      chart.chart_type.titleize
    end
  end
end
