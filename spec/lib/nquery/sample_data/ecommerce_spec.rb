# frozen_string_literal: true

require "nquery"
require_relative "../../../rails_helper"

RSpec.describe Nquery::SampleData::Ecommerce do
  let(:connection) { ActiveRecord::Base.connection }
  let(:tables) { described_class::TABLES }

  def monthly_revenue_sql
    orders = tables[:orders]
    order_items = tables[:order_items]
    <<~SQL.squish
      SELECT strftime('%Y-%m', #{orders}.ordered_at) AS month,
             ROUND(SUM(#{order_items}.quantity * #{order_items}.unit_price), 2) AS revenue
      FROM #{orders}
      INNER JOIN #{order_items} ON #{order_items}.order_id = #{orders}.id
      GROUP BY strftime('%Y-%m', #{orders}.ordered_at)
      ORDER BY month
    SQL
  end

  describe ".run!" do
    it "creates sample tables with prefixed names" do
      expect(described_class::REQUIRED_TABLES).to all(start_with("nquery_sample_"))

      described_class::REQUIRED_TABLES.each do |table|
        expect(connection.table_exists?(table)).to be(true)
      end
    end

    it "seeds data idempotently" do
      orders_table = connection.quote_table_name(tables[:orders])
      order_count = connection.select_value("SELECT COUNT(*) FROM #{orders_table}").to_i
      expect(order_count).to be_positive

      described_class.run!
      described_class.run!

      expect(connection.select_value("SELECT COUNT(*) FROM #{orders_table}").to_i).to eq(order_count)
    end

    it "returns monthly revenue rows via QueryRunner" do
      data_source = Nquery::DataSource.find_by!(name: "Main Database")
      admin = Nquery::User.find_by!(email: "admin@nquery.dev")
      runner = Nquery::QueryRunner.new(
        data_source: data_source,
        statement: monthly_revenue_sql,
        user: admin
      )

      result = runner.run

      expect(result[:row_count]).to be_positive
      expect(result[:columns]).to include("month", "revenue")
    end
  end
end
