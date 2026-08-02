# frozen_string_literal: true

module Nquery
  class ApplicationMailer < ActionMailer::Base
    default from: -> { Nquery.configuration.mailer_sender || "noreply@example.com" }
  end
end
