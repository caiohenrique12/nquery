# frozen_string_literal: true

require_relative "../../rails_helper"

RSpec.describe Nquery::CsvImporter do
  let(:creator) { Nquery::User.find_by!(email: "admin@nquery.dev") }
  let(:csv_file) do
    file = Tempfile.new(["import", ".csv"])
    file.write("name,value\nAlice,1\n")
    file.rewind
    file
  end

  after do
    csv_file.close
    csv_file.unlink
  end

  it "raises when no file is provided" do
    importer = described_class.new(file: nil, name: "Test", creator: creator)

    expect { importer.import }.to raise_error(described_class::Error, /No file provided/)
  end

  it "imports rows into a new table and data source" do
    importer = described_class.new(
      file: csv_file,
      name: "Unit import",
      creator: creator,
      column_mapping: { "name" => "name" }
    )

    upload = importer.import

    expect(upload.status).to eq("completed")
    expect(Nquery::DataSource.find_by(name: "Unit import")).to be_present
  end

  it "uses a default name when none is provided" do
    importer = described_class.new(file: csv_file, name: nil, creator: creator)

    upload = importer.import

    expect(upload.name).to start_with("Import ")
  end

  it "marks the upload as failed when import raises" do
    allow(CSV).to receive(:read).and_raise(StandardError, "boom")
    importer = described_class.new(file: csv_file, name: "Broken", creator: creator)

    expect { importer.import }.to raise_error(described_class::Error, /boom/)
    expect(Nquery::CsvUpload.last.status).to eq("failed")
  end
end
