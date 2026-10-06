# frozen_string_literal: true

module Nquery
  module Public
    class DashboardsController < PublicResourcesController
      def show
        unless Nquery.configuration.public_sharing_enabled
          return render_unavailable(status: :not_found)
        end

        @dashboard = Dashboard.active.find_by!(public_uuid: params[:uuid])
        @dashboard_cards = load_dashboard_cards(@dashboard)
        resolved = declared_dashboard_parameters
        @card_results = @dashboard_cards.index_with do |card|
          shared_chart_result(card.chart, parameters: @dashboard.parameters_for_chart(card.chart, resolved))
        end
        render template: "nquery/embed/dashboards/show"
      rescue ActiveRecord::RecordNotFound
        render_unavailable(status: :not_found)
      end

      private

      def declared_dashboard_parameters
        DashboardParameters.call(
          dashboard: @dashboard.with_agreed_chart_variables,
          token_params: {},
          request_params: {}
        )
      end
    end
  end
end
