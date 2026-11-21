# frozen_string_literal: true

module Nquery
  # Replaces {{name}} placeholders with adapter bind markers.
  class StatementBinds
    PLACEHOLDER = /\{\{\s*([a-z][a-z0-9_]*)\s*\}\}/
    OPTIONAL_CLAUSE = /\[\[(.*?)\]\]/m
    Result = Data.define(:sql, :binds)

    def self.call(statement:, parameters:, adapter:, invalid_names: [])
      new(statement:, parameters:, adapter:, invalid_names:).call
    end

    def self.missing_names(statement:, parameters:, invalid_names: [])
      new(statement:, parameters:, adapter: nil, invalid_names:).missing_names
    end

    def initialize(statement:, parameters:, adapter:, invalid_names: [])
      @statement = statement.to_s
      @parameters = parameters
      @adapter = adapter.to_s
      @invalid_names = Array(invalid_names).map(&:to_s)
    end

    def call
      binds = []
      sql = without_empty_clauses.gsub(PLACEHOLDER) do
        binds << attribute_for(Regexp.last_match(1))
        marker_for(binds.size)
      end
      raise QueryRunner::ParameterError, "Invalid parameter placeholder" if sql.include?("{{")

      Result.new(sql: sql, binds: binds)
    end

    def missing_names
      without_empty_clauses.scan(PLACEHOLDER).flatten.uniq.reject { |name| supplied?(name) || @invalid_names.include?(name) }
    end

    private

    def without_empty_clauses
      @statement.gsub(OPTIONAL_CLAUSE) do
        inner = Regexp.last_match(1)
        names = inner.scan(PLACEHOLDER).flatten
        if names.any? { |name| @invalid_names.include?(name) }
          inner
        elsif names.empty? || names.any? { |name| !supplied?(name) }
          ""
        else
          inner
        end
      end
    end

    def supplied?(name)
      return false unless values.key?(name)

      value = values[name]
      !(value.nil? || (value.is_a?(String) && value.strip.empty?))
    end

    def attribute_for(name)
      if @invalid_names.include?(name)
        raise QueryRunner::ParameterError, "Invalid value for #{name}"
      end
      unless values.key?(name)
        raise QueryRunner::ParameterError, "Unknown parameter #{name}"
      end

      value = values[name]
      if value.nil? || value.is_a?(String) && value.strip.empty?
        raise QueryRunner::ParameterError, "Missing value for #{name}"
      end
      ActiveRecord::Relation::QueryAttribute.new(name, value, bind_type_for(name, value))
    end

    def bind_type_for(name, value)
      case value
      when String then ActiveRecord::Type::String.new
      when Integer then ActiveRecord::Type::Integer.new
      when DateTime, Time then ActiveRecord::Type::DateTime.new
      when Date then ActiveRecord::Type::Date.new
      when TrueClass, FalseClass then ActiveRecord::Type::Boolean.new
      else
        raise QueryRunner::ParameterError, "Invalid value for #{name}"
      end
    end

    def values
      @values ||= case @parameters
                  when Hash
                    @parameters.stringify_keys
                  else
                    {}
                  end
    end

    def marker_for(position)
      return "$#{position}" if postgres_markers?

      "?"
    end

    def postgres_markers?
      return true if @adapter == "postgresql"
      return false unless @adapter == "rails"

      ActiveRecord::Base.connection.adapter_name.downcase.include?("postgres")
    end
  end
end
