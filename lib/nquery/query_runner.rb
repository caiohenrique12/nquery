# frozen_string_literal: true

module Nquery
  class QueryRunner
    class Error < StandardError; end
    class PermissionError < Error; end

    FORBIDDEN_KEYWORDS = /\b(INSERT|UPDATE|DELETE|DROP|ALTER|CREATE|TRUNCATE|GRANT|REVOKE|INTO)\b/i

    def initialize(data_source:, statement:, user: nil, query: nil)
      @data_source = data_source
      @statement = statement.to_s.strip
      @user = user
      @query = query
    end

    def run(audit: true)
      validate_statement!
      check_permissions!

      adapter = DataSources::Adapter.for(@data_source)
      result = adapter.execute_readonly(
        @statement,
        timeout: Nquery.configuration.query_timeout,
        row_limit: Nquery.configuration.query_row_limit
      )

      record_audit!(result, "success") if audit
      result
    rescue PermissionError
      raise
    rescue StandardError => e
      record_audit!({}, "error", e.message) if audit
      raise Error, e.message
    end

    private

    def validate_statement!
      raise Error, "Query cannot be blank" if @statement.blank?
      raise Error, "Multi-statement queries are not allowed" if @statement.include?(";")
      raise Error, "Query must start with SELECT or WITH" unless @statement.match?(/\A\s*(SELECT|WITH)\b/i)
      raise Error, "Only SELECT queries are allowed" if @statement.match?(FORBIDDEN_KEYWORDS)
    end

    def check_permissions!
      return unless @user

      resolver = Permissions::Resolver.new(@user)
      access = resolver.data_access(@data_source, permission_type: "view_data")
      raise PermissionError, "You do not have permission to view this data" if access == :blocked

      create_access = resolver.data_access(@data_source, permission_type: "create_queries")
      raise PermissionError, "You do not have permission to run SQL queries" if create_access == :no
    end

    def record_audit!(result, status, error_message = nil)
      Audit.create!(
        user: @user,
        query: @query,
        statement: @statement,
        status: status,
        row_count: result[:row_count],
        duration_ms: result[:duration_ms],
        error_message: error_message
      )
    end
  end
end
