# frozen_string_literal: true

module Nquery
  module AuthorizesCollection
    extend ActiveSupport::Concern

    COLLECTION_REQUIREMENTS = Permissions::Resolver::COLLECTION_LEVELS

    private

    def authorize_collection_access!(collection, required: :view)
      return if permission_resolver.admin?
      return if collection.nil?

      access = permission_resolver.collection_access(collection)
      required_level = COLLECTION_REQUIREMENTS.fetch(required.to_s)
      actual_level = COLLECTION_REQUIREMENTS.fetch(access.to_s, 0)
      return if actual_level >= required_level

      deny_collection_access!("You do not have permission to access this collection.")
    end

    def authorize_data_source_access!(data_source, permission_type: "view_data")
      return if permission_resolver.admin?
      return if data_source.nil?

      access = permission_resolver.data_access(data_source, permission_type: permission_type)
      blocked = permission_type == "create_queries" ? access == :no : access == :blocked
      return unless blocked

      message = permission_type == "create_queries" ? "You do not have permission to run SQL queries" : "You do not have permission to view this data"
      deny_collection_access!(message)
    end

    def viewable_collection?(collection)
      return true if permission_resolver.admin?
      return false if collection.nil?

      permission_resolver.collection_access(collection) != :no_access
    end

    def deny_collection_access!(message)
      if request.format.json?
        render json: { error: message }, status: :forbidden
      else
        redirect_to root_path, alert: message
      end
    end
  end
end
