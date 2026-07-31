# frozen_string_literal: true

module Nquery
  module Onboarding
    module_function

    def required?
      !complete?
    end

    def complete?
      Organization.exists? && (onboarding_latched? || confirmed_admin_exists?)
    end

    def pending_admin_confirmation?
      return false if complete?
      return false unless Organization.exists?

      unconfirmed_admin_exists?
    end

    def onboarding_latched?
      Organization.where.not(onboarding_completed_at: nil).exists?
    end

    def confirmed_admin_exists?
      administrators = Group.find_by(system_group: "administrators")
      return false unless administrators

      administrators.users.active.where.not(confirmed_at: nil).exists?
    end

    def unconfirmed_admin_exists?
      administrators = Group.find_by(system_group: "administrators")
      return false unless administrators

      administrators.users.active.where(confirmed_at: nil).exists?
    end
  end
end
