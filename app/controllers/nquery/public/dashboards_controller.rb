# frozen_string_literal: true

module Nquery
  module Public
    class DashboardsController < PublicResourcesController
      def show
        unless Nquery.configuration.public_sharing_enabled
          return render_unavailable(status: :not_found)
        end

        @dashboard = Dashboard.find_by!(public_uuid: params[:uuid])
        @dashboard_cards = load_dashboard_cards(@dashboard)
        @card_results = @dashboard_cards.index_with { |card| shared_chart_result(card.chart) }
        render template: "nquery/embed/dashboards/show"
      rescue ActiveRecord::RecordNotFound
        render_unavailable(status: :not_found)
      end
    end
  end
end
