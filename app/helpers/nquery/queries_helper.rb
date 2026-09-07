# frozen_string_literal: true

module Nquery
  module QueriesHelper
    def query_editor_data
      {
        controller: "query-editor",
        query_run_url: run_queries_path
      }
    end
  end
end
