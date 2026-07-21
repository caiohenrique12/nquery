# frozen_string_literal: true

module Nquery
  class GroupMembership < ApplicationRecord
    belongs_to :user, class_name: "Nquery::User"
    belongs_to :group, class_name: "Nquery::Group"

    validates :user_id, uniqueness: { scope: :group_id }
  end
end
