# frozen_string_literal: true

module Nquery
  class Configuration
    attr_accessor :authentication_mode
    attr_accessor :current_user_method
    attr_accessor :parent_controller
    attr_accessor :data_sources
    attr_accessor :query_timeout
    attr_accessor :query_row_limit
    attr_accessor :embed_secret

    def initialize
      @authentication_mode = :standalone
      @current_user_method = :current_nquery_user
      @data_sources = { main: :rails }
      @query_timeout = 15
      @query_row_limit = 10_000
      @embed_secret = nil
      @authenticate_with = nil
      @resolve_nquery_user = nil
    end

    def authenticate_with(&block)
      @authenticate_with = block
    end

    def authenticate
      @authenticate_with
    end

    def resolve_nquery_user(&block)
      @resolve_nquery_user = block
    end

    def resolve_user
      @resolve_nquery_user
    end

    def embed_signing_key
      embed_secret || Rails.application.secret_key_base
    end
  end
end
