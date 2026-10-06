# frozen_string_literal: true

module Nquery
  module ChartResults
    extend ActiveSupport::Concern

    private

    def chart_result(chart, parameters: nil)
      return demo_result unless chart.statement?

      resolved = parameters || query_default_parameters(chart)
      chart_query_result(chart, parameters: resolved)
    rescue QueryRunner::ParameterError => error
      { error: parameter_load_error(chart.statement, resolved, error) }
    rescue QueryRunner::Error => error
      Rails.logger.error("[nquery] chart #{chart.id} failed: #{error.class}: #{error.message}")
      { error: shared_chart_load_error }
    rescue StandardError
      demo_result
    end

    def chart_builder_result(chart)
      return nil unless chart.statement?

      chart_query_result(chart, audit: false, parameters: query_default_parameters(chart))
    rescue QueryRunner::PermissionError, QueryRunner::Error => e
      { error: e.message }
    rescue StandardError => e
      { error: e.message }
    end

    def shared_chart_result(chart, parameters: nil)
      return { error: "This chart has no query." } unless chart.statement?
      return { error: shared_chart_load_error } unless chart.data_source

      chart_query_result(chart, audit: false, parameters: parameters)
    rescue QueryRunner::ParameterError => error
      { error: parameter_load_error(chart.statement, parameters, error) }
    rescue StandardError => e
      Rails.logger.error("[nquery] shared chart #{chart.id} failed: #{e.class}: #{e.message}")
      { error: shared_chart_load_error }
    end

    def query_default_parameters(chart)
      return unless chart.query

      DashboardParameters.call(dashboard: chart.query, token_params: {}, request_params: {})
    end

    def chart_query_result(chart, audit: true, parameters: nil)
      QueryRunner.new(
        data_source: chart.data_source || DataSource.first,
        statement: chart.statement,
        user: current_nquery_user,
        query: chart.query,
        parameters: parameters
      ).run(audit: audit)
    end

    def demo_result
      {
        columns: %w[month revenue],
        rows: [%w[Jan 1200], %w[Feb 1800], %w[Mar 2400], %w[Apr 2100]],
        row_count: 4
      }
    end

    def shared_chart_load_error
      "This chart could not be loaded."
    end

    def parameter_load_error(statement, parameters, error)
      return shared_chart_load_error unless error.message.match?(/\A(?:Missing value for|Unknown parameter) /)

      names = StatementBinds.missing_names(
        statement: statement,
        parameters: parameter_value_hash(parameters),
        invalid_names: parameter_invalid_names(parameters)
      )
      return shared_chart_load_error if names.empty?

      labels = names.map { |name| name.tr("_", " ").capitalize }
      if labels.one?
        "Enter a value for #{labels.first}."
      else
        "Enter values for #{labels.to_sentence}."
      end
    end

    def parameter_value_hash(parameters)
      case parameters
      when DashboardParameters::Result then parameters.values
      when Hash then parameters
      else {}
      end
    end

    def parameter_invalid_names(parameters)
      return parameters.invalid_names if parameters.is_a?(DashboardParameters::Result)

      []
    end
  end
end
