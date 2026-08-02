# frozen_string_literal: true

require_relative "../../rails_helper"

RSpec.describe Nquery::Organization do
  it "requires a name" do
    organization = described_class.new

    expect(organization).not_to be_valid
    expect(organization.errors[:name]).to be_present
  end

  it "allows optional website" do
    organization = described_class.new(name: "Acme")

    expect(organization).to be_valid
  end

  it "supports logo and cover image attachments" do
    organization = described_class.create!(name: "Acme")
    organization.logo.attach(
      io: StringIO.new("logo"),
      filename: "logo.png",
      content_type: "image/png"
    )
    organization.cover_image.attach(
      io: StringIO.new("cover"),
      filename: "cover.png",
      content_type: "image/png"
    )

    expect(organization.logo).to be_attached
    expect(organization.cover_image).to be_attached
    expect(organization).to be_valid
  end

  it "rejects logos with an unsupported content type" do
    organization = described_class.create!(name: "Acme")
    organization.logo.attach(
      io: StringIO.new("%PDF-1.4"),
      filename: "malware.pdf",
      content_type: "application/pdf"
    )

    expect(organization).not_to be_valid
    expect(organization.errors[:logo]).to include("must be a PNG, JPEG, WebP, or GIF")
  end

  it "rejects cover images that exceed the size limit" do
    organization = described_class.create!(name: "Acme")
    organization.cover_image.attach(
      io: StringIO.new("x" * (5.megabytes + 1)),
      filename: "huge.png",
      content_type: "image/png"
    )

    expect(organization).not_to be_valid
    expect(organization.errors[:cover_image]).to include("is too large (maximum is 5 MB)")
  end
end
