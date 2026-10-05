# frozen_string_literal: true

require_relative "../../rails_helper"

RSpec.describe Nquery::StatementBinds do
  let(:start_date) { Date.new(2026, 8, 1) }
  let(:end_date) { Date.new(2026, 8, 7) }

  describe ".call" do
    it "replaces each placeholder with a marker and a date bind" do
      result = described_class.call(
        statement: "SELECT 1 WHERE {{start_date}} = {{ start_date }}",
        parameters: { "start_date" => start_date },
        adapter: "sqlite"
      )

      expect(result.sql).to eq("SELECT 1 WHERE ? = ?")
      expect(result.binds.size).to eq(2)
      expect(result.binds).to all(be_a(ActiveRecord::Relation::QueryAttribute))
      expect(result.binds.map(&:value)).to eq([start_date, start_date])
      expect(result.sql).not_to include("2026-08-01")
    end

    it "numbers postgresql markers once per occurrence" do
      result = described_class.call(
        statement: "SELECT 1 WHERE {{start_date}} = {{start_date}} AND {{end_date}} > {{start_date}}",
        parameters: { "start_date" => start_date, "end_date" => end_date },
        adapter: "postgresql"
      )

      expect(result.sql).to eq("SELECT 1 WHERE $1 = $2 AND $3 > $4")
      expect(result.binds.map(&:value)).to eq([start_date, start_date, end_date, start_date])
    end

    it "uses question marks when the rails connection is sqlite" do
      result = described_class.call(
        statement: "SELECT 1 WHERE {{start_date}} = {{end_date}}",
        parameters: { "start_date" => start_date, "end_date" => end_date },
        adapter: "rails"
      )

      expect(result.sql).to eq("SELECT 1 WHERE ? = ?")
    end

    it "uses numbered markers when the rails connection is postgres" do
      connection = ActiveRecord::Base.connection
      allow(connection).to receive(:adapter_name).and_return("PostgreSQL")

      result = described_class.call(
        statement: "SELECT 1 WHERE {{start_date}} = {{end_date}}",
        parameters: { "start_date" => start_date, "end_date" => end_date },
        adapter: "rails"
      )

      expect(result.sql).to eq("SELECT 1 WHERE $1 = $2")
    end

    it "raises when a placeholder is unknown" do
      expect {
        described_class.call(
          statement: "SELECT {{other}}",
          parameters: { "start_date" => start_date },
          adapter: "sqlite"
        )
      }.to raise_error(Nquery::QueryRunner::ParameterError, "Unknown parameter other")
    end

    it "raises when a placeholder is left open" do
      expect {
        described_class.call(
          statement: "SELECT 1 WHERE created_at >= {{start_date",
          parameters: { "start_date" => start_date },
          adapter: "sqlite"
        )
      }.to raise_error(Nquery::QueryRunner::ParameterError, "Invalid parameter placeholder")
    end

    it "raises when a value is missing" do
      expect {
        described_class.call(
          statement: "SELECT 1 WHERE {{start_date}} = 1",
          parameters: { "start_date" => nil },
          adapter: "sqlite"
        )
      }.to raise_error(Nquery::QueryRunner::ParameterError, "Missing value for start_date")
    end

    it "raises when a value is not a date and keeps it out of the message" do
      raw = "2026-08-01' OR '1'='1"

      expect {
        described_class.call(
          statement: "SELECT 1 WHERE {{start_date}} = 1",
          parameters: { "start_date" => raw },
          adapter: "sqlite"
        )
      }.to raise_error(Nquery::QueryRunner::ParameterError, "Invalid value for start_date") { |error|
        expect(error.message).not_to include(raw)
      }
    end
  end
end
