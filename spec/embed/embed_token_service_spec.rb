# frozen_string_literal: true

require "nquery"
require "spec_helper"

RSpec.describe Nquery::EmbedTokenService do
  let(:user) { Nquery::User.create!(email: "embed@example.com", password: "password123") }

  it "creates and verifies signed tokens" do
    result = described_class.sign(resource_type: "Nquery::Chart", resource_id: 1, creator: user)
    payload = described_class.verify(result[:signed_token])
    expect(payload[:resource_id]).to eq(1)
  end

  it "rejects tampered signatures" do
    result = described_class.sign(resource_type: "Nquery::Chart", resource_id: 1, creator: user)
    data, = result[:signed_token].split(".", 2)
    tampered = "#{data}.invalidsignature"

    expect { described_class.verify(tampered) }.to raise_error(Nquery::EmbedTokenService::Error, /signature/)
  end

  it "rejects plain tokens without a signature" do
    result = described_class.sign(resource_type: "Nquery::Chart", resource_id: 1, creator: user)

    expect { described_class.verify(result[:token]) }.to raise_error(Nquery::EmbedTokenService::Error, /format/)
  end

  it "builds signed tokens from persisted records" do
    result = described_class.sign(resource_type: "Nquery::Chart", resource_id: 42, creator: user)
    record = Nquery::EmbedToken.find_by!(token: result[:token])
    signed = described_class.signed_token_for(record)

    expect(described_class.verify(signed)[:resource_id]).to eq(42)
  end
end
