# frozen_string_literal: true

module Nquery
  class Configuration
    attr_accessor :parent_controller
    attr_accessor :data_sources
    attr_accessor :default_data_source
    attr_accessor :mailer_sender
    attr_accessor :smtp
    attr_accessor :query_timeout
    attr_accessor :query_row_limit
    attr_accessor :embed_secret
    attr_accessor :public_sharing_enabled
    attr_accessor :static_embedding_enabled
    attr_accessor :embed_frame_ancestors

    def initialize
      @data_sources = { main: { adapter: :rails, name: "Application database" } }
      @default_data_source = :main
      @mailer_sender = nil
      @smtp = {}
      @query_timeout = 15
      @query_row_limit = 10_000
      @embed_secret = nil
      @public_sharing_enabled = false
      @static_embedding_enabled = false
      @embed_frame_ancestors = nil
    end

    def embed_signing_key
      embed_secret || Rails.application.secret_key_base
    end
  end
end
