# frozen_string_literal: true

module Nquery
  module IconHelper
    def nq_icon(name, **options)
      render "nquery/shared/icon", name: name.to_s, html_options: options
    end
  end
end
