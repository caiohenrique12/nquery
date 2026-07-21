# frozen_string_literal: true

pin "application", preload: true
pin "@hotwired/turbo-rails", to: "turbo.min.js", preload: true
pin "@hotwired/stimulus", to: "stimulus.min.js", preload: true
pin "@hotwired/stimulus-loading", to: "stimulus-loading.js", preload: true
pin_all_from Nquery::Engine.root.join("app/javascript/nquery/controllers"), under: "nquery/controllers"
pin "nquery/chart", to: "nquery/chart.bundle.js"
pin "nquery/application", to: "nquery/application.js"
