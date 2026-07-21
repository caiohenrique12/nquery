# frozen_string_literal: true

namespace :nquery do
  desc "Seed demo data for nquery"
  task seed: :environment do
    Nquery::Seeder.run!
    puts "nquery: seed complete"
  end
end
