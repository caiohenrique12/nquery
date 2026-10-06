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

    it "drops an optional clause when its value is missing" do
      result = described_class.call(
        statement: "SELECT 1 WHERE 1 = 1 [[AND created_at >= {{start_date}}]]",
        parameters: {},
        adapter: "sqlite"
      )

      expect(result.sql).to eq("SELECT 1 WHERE 1 = 1 ")
      expect(result.binds).to eq([])
    end

    it "keeps an optional clause when its value is present" do
      result = described_class.call(
        statement: "SELECT 1 WHERE 1 = 1 [[AND created_at >= {{start_date}}]]",
        parameters: { "start_date" => start_date },
        adapter: "sqlite"
      )

      expect(result.sql).to eq("SELECT 1 WHERE 1 = 1 AND created_at >= ?")
      expect(result.binds.map(&:value)).to eq([start_date])
    end

    it "raises when an optional clause has an invalid value" do
      expect {
        described_class.call(
          statement: "SELECT 1 [[WHERE {{start_date}} = 1]]",
          parameters: {},
          invalid_names: ["start_date"],
          adapter: "sqlite"
        )
      }.to raise_error(Nquery::QueryRunner::ParameterError, "Invalid value for start_date")
    end

    it "keeps an optional clause when the boolean value is false" do
      result = described_class.call(
        statement: "SELECT 1 WHERE 1 = 1 [[AND active = {{active}}]]",
        parameters: { "active" => false },
        adapter: "sqlite"
      )

      expect(result.sql).to eq("SELECT 1 WHERE 1 = 1 AND active = ?")
      expect(result.binds.map(&:value)).to eq([false])
      expect(result.binds.first.type).to be_a(ActiveRecord::Type::Boolean)
    end

    it "lists required placeholders that have no value" do
      names = described_class.missing_names(
        statement: "SELECT {{label}} AS label, {{qty}} AS qty [[AND created_at >= {{start_date}}]]",
        parameters: { "label" => "" }
      )

      expect(names).to eq(%w[label qty])
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

    it "binds a string without writing it into the sql" do
      raw = "north' OR '1'='1"
      result = described_class.call(
        statement: "SELECT 1 WHERE {{region}} = 'kept'",
        parameters: { "region" => raw },
        adapter: "sqlite"
      )

      expect(result.sql).to eq("SELECT 1 WHERE ? = 'kept'")
      expect(result.sql).not_to include(raw)
      expect(result.binds.map(&:value)).to eq([raw])
    end

    it "binds a time without writing it into the sql" do
      value = Time.zone.parse("2026-08-01T15:30")
      result = described_class.call(
        statement: "SELECT 1 WHERE {{as_of}} = 1",
        parameters: { "as_of" => value },
        adapter: "sqlite"
      )

      expect(result.sql).to eq("SELECT 1 WHERE ? = 1")
      expect(result.sql).not_to include("2026-08-01")
      expect(result.binds.map(&:value)).to eq([value])
    end

    it "binds an integer without writing it into the sql" do
      result = described_class.call(
        statement: "SELECT 1 WHERE {{minimum}} = 1",
        parameters: { "minimum" => 42 },
        adapter: "sqlite"
      )

      expect(result.sql).to eq("SELECT 1 WHERE ? = 1")
      expect(result.sql).not_to include("42")
      expect(result.binds.map(&:value)).to eq([42])
    end

    it "raises when a value is not a supported parameter type and keeps it out of the message" do
      expect {
        described_class.call(
          statement: "SELECT 1 WHERE {{start_date}} = 1",
          parameters: { "start_date" => { "bad" => true } },
          adapter: "sqlite"
        )
      }.to raise_error(Nquery::QueryRunner::ParameterError, "Invalid value for start_date") { |error|
        expect(error.message).not_to include("bad")
      }
    end
  end
end
