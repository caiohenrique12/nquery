# frozen_string_literal: true

namespace :nquery do
  desc "Provision default groups, data sources, and permissions"
  task setup: :environment do
    Nquery::Setup.run!
    puts "nquery: setup complete"
  end

  desc "Seed demo data for nquery"
  task seed: :environment do
    Nquery::Seeder.run!
    puts "nquery: seed complete"
  end
end
