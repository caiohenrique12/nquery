# frozen_string_literal: true

class AddOnboardingCompletedAtToNqueryOrganizations < ActiveRecord::Migration[8.0]
  def change
    add_column :nquery_organizations, :onboarding_completed_at, :datetime
  end
end
