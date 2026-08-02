# frozen_string_literal: true

require "turbo-rails"
require "devise"
require "devise/orm/active_record"

require "nquery/version"
require "nquery/configuration"
require "nquery/encryption"
require "nquery/permissions/resolver"
require "nquery/authorizes_collection"
require "nquery/data_sources/adapter"
require "nquery/data_sources/rails_adapter"
require "nquery/data_sources/postgresql_adapter"
require "nquery/data_sources/mysql_adapter"
require "nquery/data_sources/sqlite_adapter"
require "nquery/data_sources/syncer"
require "nquery/readonly_sql"
require "nquery/query_runner"
require "nquery/schema_explorer"
require "nquery/embed_token_service"
require "nquery/csv_importer"
require "nquery/sample_data/ecommerce"
require "nquery/setup"
require "nquery/onboarding"
require "nquery/onboarding/admin_provisioner"
require "nquery/onboarding/password_confirmation"
require "nquery/seeder"
require "nquery/engine"

module Nquery
  class << self
    def configuration
      @configuration ||= Configuration.new
    end

    def configure
      yield(configuration)
    end

    def reset_configuration!
      @configuration = Configuration.new
    end
  end
end
