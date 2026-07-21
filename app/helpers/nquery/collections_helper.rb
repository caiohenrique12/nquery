# frozen_string_literal: true

module Nquery
  module CollectionsHelper
    def collection_kind_label(collection)
      case collection.kind
      when "root" then "Top-level collection"
      when "personal" then "Personal collection"
      else "Collection"
      end
    end
  end
end
