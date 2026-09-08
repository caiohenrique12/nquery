# frozen_string_literal: true

module Nquery
  module Public
    class ChartsController < PublicResourcesController
      def show
        unless Nquery.configuration.public_sharing_enabled
          return render_unavailable(status: :not_found)
        end

        @chart = Chart.active.find_by!(public_uuid: params[:uuid])
        @result = shared_chart_result(@chart)
        render template: "nquery/embed/charts/show"
      rescue ActiveRecord::RecordNotFound
        render_unavailable(status: :not_found)
      end
    end
  end
end
