# frozen_string_literal: true

require_relative "../../rails_helper"

RSpec.describe "Authentication", type: :request do
  describe "protected routes" do
    it "redirects unauthenticated users to login" do
      get "/collections"

      expect(response).to redirect_to("/login")
      expect(flash[:alert]).to eq("Please sign in to continue.")
    end
  end

  describe "custom authentication" do
    around do |example|
      original = Nquery.configuration.authenticate
      Nquery.configure do |config|
        config.authenticate_with do
          redirect_to "/login", alert: "Custom auth required." unless session[:custom_auth]
        end
      end
      example.run
      Nquery.configuration.instance_variable_set(:@authenticate_with, original)
    end

    it "uses a custom authenticate block" do
      get "/collections"

      expect(response).to redirect_to("/login")
      expect(flash[:alert]).to eq("Custom auth required.")
    end
  end

  describe "SSO user resolution" do
    let(:host_user) { double(id: 42, email: "sso@example.com", first_name: "SSO", name: nil) }

    around do |example|
      original_mode = Nquery.configuration.authentication_mode
      original_resolver = Nquery.configuration.resolve_user
      Nquery.configure do |config|
        config.authentication_mode = :sso
        config.resolve_nquery_user { |user| Nquery::User.find_or_create_from_sso!(user) }
      end
      example.run
      Nquery.configuration.authentication_mode = original_mode
      Nquery.configuration.instance_variable_set(:@resolve_nquery_user, original_resolver)
    end

    it "resolves users from the host application" do
      controller = Nquery::ApplicationController.new
      allow(controller).to receive(:session).and_return({})
      allow(controller).to receive(:send).and_call_original
      allow(controller).to receive(:send).with(:current_nquery_user).and_return(host_user)

      user = controller.send(:resolve_current_user)

      expect(user.email).to eq("sso@example.com")
    end
  end
end
