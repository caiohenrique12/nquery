# frozen_string_literal: true

module Nquery
  class Audit < ApplicationRecord
    belongs_to :user, class_name: "Nquery::User", optional: true
    belongs_to :query, class_name: "Nquery::Query", optional: true

    scope :recent, -> { order(created_at: :desc) }

    scope :for_user, lambda { |term|
      pattern = "%#{sanitize_sql_like(term.downcase)}%"
      full_name_sql = if connection.adapter_name.downcase.include?("mysql")
        "CONCAT(nquery_users.first_name, ' ', nquery_users.last_name)"
                      else
        "nquery_users.first_name || ' ' || nquery_users.last_name"
                      end

      joins(:user).where(
        "LOWER(nquery_users.email) LIKE :q OR LOWER(#{full_name_sql}) LIKE :q",
        q: pattern
      )
    }

    scope :for_collection, ->(collection_id) {
      joins(query: :collection).where(nquery_collections: { id: collection_id })
    }

    scope :for_dashboard, lambda { |dashboard_id|
      dashboard_audit_ids = joins(query: { chart: { dashboard_cards: :dashboard } })
        .where(nquery_dashboards: { id: dashboard_id })
        .select(:id)
      where(id: dashboard_audit_ids)
    }

    scope :since, ->(date) { where(created_at: Date.parse(date).beginning_of_day..) }
    scope :until_date, ->(date) { where(created_at: ..Date.parse(date).end_of_day) }
  end
end
