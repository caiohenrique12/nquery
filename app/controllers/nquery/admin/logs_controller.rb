# frozen_string_literal: true

module Nquery
  module Admin
    class LogsController < BaseController
      def index
        @collections = Collection.order(:name)
        @dashboards = Dashboard.order(:name)
        @audits = filtered_audits
          .includes(:user, query: [:collection, { chart: { dashboard_cards: :dashboard } }])
          .recent
          .limit(100)
      end

      private

      def filtered_audits
        scope = Audit.all
        scope = scope.for_user(params[:user]) if params[:user].present?
        scope = scope.for_collection(params[:collection]) if params[:collection].present?
        scope = scope.for_dashboard(params[:dashboard]) if params[:dashboard].present?
        scope = scope.since(params[:from]) if params[:from].present?
        scope = scope.until_date(params[:to]) if params[:to].present?
        scope
      end
    end
  end
end
