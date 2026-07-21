# frozen_string_literal: true

module Nquery
  module NavigationHelper
    def nav_link_class(*controller_paths)
      active = controller_paths.flatten.any? { |path| controller_path == path.to_s }
      active ? "nq-nav-link active" : "nq-nav-link"
    end
  end
end
