# frozen_string_literal: true

module Nquery
  module GroupsHelper
    GROUP_TYPE_LABELS = {
      "administrators" => "Administrators",
      "all_users" => "All users",
      "custom" => "Custom"
    }.freeze

    def group_type_label(group)
      GROUP_TYPE_LABELS.fetch(group.system_group, group.system_group.humanize)
    end

    def group_type_badge_class(group)
      group.system? ? "nq-badge-system" : "nq-badge-custom"
    end
  end
end
