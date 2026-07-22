# frozen_string_literal: true

module Nquery
  module SampleData
    class Ecommerce
      TABLES = {
        categories: "nquery_sample_categories",
        products: "nquery_sample_products",
        customers: "nquery_sample_customers",
        orders: "nquery_sample_orders",
        order_items: "nquery_sample_order_items"
      }.freeze

      REQUIRED_TABLES = TABLES.values.freeze

      def self.run!
        new.run!
      end

      def run!
        connection = ActiveRecord::Base.connection
        create_tables!(connection)
        return if seeded?(connection)

        seed!(connection)
      end

      private

      def create_tables!(connection)
        create_table_if_missing(connection, TABLES[:categories]) do |t|
          t.string :name, null: false
          t.timestamps
        end

        create_table_if_missing(connection, TABLES[:products]) do |t|
          t.references :category, null: false, foreign_key: { to_table: TABLES[:categories] }
          t.string :name, null: false
          t.decimal :price, precision: 10, scale: 2, null: false
          t.timestamps
        end

        create_table_if_missing(connection, TABLES[:customers]) do |t|
          t.string :email, null: false
          t.string :first_name, null: false
          t.string :last_name, null: false
          t.timestamps
        end
        connection.add_index TABLES[:customers], :email, unique: true unless connection.index_exists?(TABLES[:customers], :email)

        create_table_if_missing(connection, TABLES[:orders]) do |t|
          t.references :customer, null: false, foreign_key: { to_table: TABLES[:customers] }
          t.string :status, null: false, default: "completed"
          t.datetime :ordered_at, null: false
          t.timestamps
        end

        create_table_if_missing(connection, TABLES[:order_items]) do |t|
          t.references :order, null: false, foreign_key: { to_table: TABLES[:orders] }
          t.references :product, null: false, foreign_key: { to_table: TABLES[:products] }
          t.integer :quantity, null: false, default: 1
          t.decimal :unit_price, precision: 10, scale: 2, null: false
          t.timestamps
        end
      end

      def create_table_if_missing(connection, table_name, &block)
        return if connection.table_exists?(table_name)

        connection.create_table(table_name, &block)
      end

      def seeded?(connection)
        connection.select_value(
          "SELECT COUNT(*) FROM #{connection.quote_table_name(TABLES[:orders])}"
        ).to_i.positive?
      end

      def seed!(connection)
        now = Time.current
        categories = {
          electronics: insert_row(connection, TABLES[:categories], name: "Electronics", created_at: now, updated_at: now),
          apparel: insert_row(connection, TABLES[:categories], name: "Apparel", created_at: now, updated_at: now),
          home: insert_row(connection, TABLES[:categories], name: "Home", created_at: now, updated_at: now)
        }

        products = {
          headphones: insert_row(connection, TABLES[:products], category_id: categories[:electronics], name: "Wireless Headphones", price: 79.99, created_at: now, updated_at: now),
          keyboard: insert_row(connection, TABLES[:products], category_id: categories[:electronics], name: "Mechanical Keyboard", price: 129.99, created_at: now, updated_at: now),
          mouse: insert_row(connection, TABLES[:products], category_id: categories[:electronics], name: "Ergonomic Mouse", price: 49.99, created_at: now, updated_at: now),
          hoodie: insert_row(connection, TABLES[:products], category_id: categories[:apparel], name: "Cotton Hoodie", price: 59.99, created_at: now, updated_at: now),
          tshirt: insert_row(connection, TABLES[:products], category_id: categories[:apparel], name: "Logo T-Shirt", price: 24.99, created_at: now, updated_at: now),
          mug: insert_row(connection, TABLES[:products], category_id: categories[:home], name: "Ceramic Mug", price: 14.99, created_at: now, updated_at: now),
          lamp: insert_row(connection, TABLES[:products], category_id: categories[:home], name: "Desk Lamp", price: 39.99, created_at: now, updated_at: now)
        }

        customers = [
          insert_row(connection, TABLES[:customers], email: "alice@example.com", first_name: "Alice", last_name: "Nguyen", created_at: now, updated_at: now),
          insert_row(connection, TABLES[:customers], email: "bob@example.com", first_name: "Bob", last_name: "Martinez", created_at: now, updated_at: now),
          insert_row(connection, TABLES[:customers], email: "carol@example.com", first_name: "Carol", last_name: "Patel", created_at: now, updated_at: now),
          insert_row(connection, TABLES[:customers], email: "dan@example.com", first_name: "Dan", last_name: "Kim", created_at: now, updated_at: now),
          insert_row(connection, TABLES[:customers], email: "eva@example.com", first_name: "Eva", last_name: "Silva", created_at: now, updated_at: now)
        ]

        order_specs = [
          { customer: customers[0], ordered_at: Time.zone.parse("2026-01-05 10:00"), items: [[:headphones, 1], [:mug, 2]] },
          { customer: customers[1], ordered_at: Time.zone.parse("2026-01-12 14:30"), items: [[:keyboard, 1], [:mouse, 1]] },
          { customer: customers[2], ordered_at: Time.zone.parse("2026-01-20 09:15"), items: [[:hoodie, 2], [:tshirt, 1]] },
          { customer: customers[3], ordered_at: Time.zone.parse("2026-02-03 11:00"), items: [[:lamp, 1], [:mug, 1]] },
          { customer: customers[4], ordered_at: Time.zone.parse("2026-02-14 16:45"), items: [[:headphones, 1], [:tshirt, 2]] },
          { customer: customers[0], ordered_at: Time.zone.parse("2026-02-22 08:20"), items: [[:mouse, 2]] },
          { customer: customers[1], ordered_at: Time.zone.parse("2026-03-01 13:10"), items: [[:keyboard, 1], [:hoodie, 1]] },
          { customer: customers[2], ordered_at: Time.zone.parse("2026-03-08 17:30"), items: [[:lamp, 2], [:mug, 3]] },
          { customer: customers[3], ordered_at: Time.zone.parse("2026-03-15 10:50"), items: [[:headphones, 2], [:keyboard, 1]] },
          { customer: customers[4], ordered_at: Time.zone.parse("2026-03-21 19:00"), items: [[:tshirt, 3], [:mouse, 1]] }
        ]

        order_specs.each do |spec|
          order_id = insert_row(
            connection,
            TABLES[:orders],
            customer_id: spec[:customer],
            status: "completed",
            ordered_at: spec[:ordered_at],
            created_at: now,
            updated_at: now
          )

          spec[:items].each do |product_key, quantity|
            product_id = products[product_key]
            unit_price = connection.select_value(
              "SELECT price FROM #{connection.quote_table_name(TABLES[:products])} WHERE id = #{connection.quote(product_id)}"
            )
            insert_row(
              connection,
              TABLES[:order_items],
              order_id: order_id,
              product_id: product_id,
              quantity: quantity,
              unit_price: unit_price,
              created_at: now,
              updated_at: now
            )
          end
        end
      end

      def insert_row(connection, table, attrs)
        columns = attrs.keys
        values = attrs.values.map { |value| connection.quote(value) }
        connection.insert(
          "INSERT INTO #{connection.quote_table_name(table)} (#{columns.map { |c| connection.quote_column_name(c) }.join(', ')}) VALUES (#{values.join(', ')})"
        )
      end
    end
  end
end
