# frozen_string_literal: true

module Nquery
  # Replaces {{name}} placeholders with adapter bind markers.
  class StatementBinds
    PLACEHOLDER = /\{\{\s*([a-z][a-z0-9_]*)\s*\}\}/
    Result = Data.define(:sql, :binds)

    def self.call(statement:, parameters:, adapter:, invalid_names: [])
      new(statement:, parameters:, adapter:, invalid_names:).call
    end

    def initialize(statement:, parameters:, adapter:, invalid_names: [])
      @statement = statement.to_s
      @parameters = parameters
      @adapter = adapter.to_s
      @invalid_names = Array(invalid_names).map(&:to_s)
    end

    def call
      binds = []
      sql = @statement.gsub(PLACEHOLDER) do
        binds << attribute_for(Regexp.last_match(1))
        marker_for(binds.size)
      end
      raise QueryRunner::ParameterError, "Invalid parameter placeholder" if sql.include?("{{")

      Result.new(sql: sql, binds: binds)
    end

    private

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
      unless value.instance_of?(::Date)
        raise QueryRunner::ParameterError, "Invalid value for #{name}"
      end

      ActiveRecord::Relation::QueryAttribute.new(name, value, ActiveRecord::Type::Date.new)
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
