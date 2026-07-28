# frozen_string_literal: true

module Nquery
  # Validates that a SQL statement is read-only (SELECT / WITH … SELECT).
  module ReadonlySql
    FORBIDDEN_KEYWORDS = /\b(
      INSERT|UPDATE|DELETE|DROP|ALTER|CREATE|TRUNCATE|
      GRANT|REVOKE|INTO|MERGE|REPLACE|CALL|EXEC|EXECUTE|
      COPY|ATTACH|DETACH|VACUUM|PRAGMA|REINDEX|RENAME
    )\b/ix

    module_function

    def error_message(statement, allow_blank: false)
      sql = statement.to_s.strip

      return "Query cannot be blank" if sql.blank? && !allow_blank
      return nil if sql.blank?

      return "Multi-statement queries are not allowed" if sql.include?(";")
      return "Query must start with SELECT or WITH" unless sql.match?(/\A\s*(SELECT|WITH)\b/i)
      return "Only SELECT queries are allowed" if sql.match?(FORBIDDEN_KEYWORDS)

      nil
    end
  end
end
