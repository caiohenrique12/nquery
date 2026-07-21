# frozen_string_literal: true

Rails.application.configure do
  if config.respond_to?(:assets)
    config.assets.paths << Nquery::Engine.root.join("app/assets/builds")
    config.assets.paths << Nquery::Engine.root.join("app/assets/images")
  end
end
