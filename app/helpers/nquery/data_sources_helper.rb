# frozen_string_literal: true

module Nquery
  module DataSourcesHelper
    def data_source_form_url(data_source)
      data_source.persisted? ? admin_data_source_path(data_source) : admin_data_sources_path
    end

    def data_source_form_method(data_source)
      data_source.persisted? ? :patch : :post
    end
  end
end
