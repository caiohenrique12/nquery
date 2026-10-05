# frozen_string_literal: true

require_relative "../../../rails_helper"

RSpec.describe Nquery::DataSources::RowLimit do
  describe ".apply" do
    subject(:sql) { described_class.apply(statement, limit) }

    let(:limit) { 10_000 }

    context "when the statement has no limit" do
      let(:statement) { "SELECT 1 AS value" }

      it "appends the cap on the next line" do
        expect(sql).to eq("SELECT 1 AS value\nLIMIT 10000")
      end

      context "with a trailing semicolon" do
        let(:statement) { "SELECT 1 AS value;" }

        it "strips the semicolon before appending the cap" do
          expect(sql).to eq("SELECT 1 AS value\nLIMIT 10000")
        end
      end

      context "with a trailing line comment" do
        let(:statement) { "SELECT 1 AS value UNION ALL SELECT 2 -- all" }
        let(:limit) { 2 }

        it "appends the cap on the next line" do
          expect(sql).to eq("#{statement}\nLIMIT 2")
        end
      end

      context "when a limit sits only inside a trailing comment" do
        let(:statement) { "SELECT 1 UNION ALL SELECT 2 -- LIMIT 5" }
        let(:limit) { 2 }

        it "appends the cap on the next line" do
          expect(sql).to eq("#{statement}\nLIMIT 2")
        end
      end

      context "when a block comment is left unclosed" do
        let(:statement) { "SELECT 1 AS id UNION ALL SELECT 2 UNION ALL SELECT 3 /*" }
        let(:limit) { 2 }

        it "places the cap before the comment" do
          expect(sql).to eq("SELECT 1 AS id UNION ALL SELECT 2 UNION ALL SELECT 3\nLIMIT 2 /*\n")
        end
      end

      context "when a limit sits only inside an unclosed block comment" do
        let(:statement) { "SELECT 1 UNION ALL SELECT 2 UNION ALL SELECT 3 /* LIMIT 1" }
        let(:limit) { 2 }

        it "places the cap before the comment" do
          expect(sql).to eq("SELECT 1 UNION ALL SELECT 2 UNION ALL SELECT 3\nLIMIT 2 /* LIMIT 1")
        end
      end

      context "when a block comment opener sits inside a string" do
        let(:statement) { "SELECT '/*' AS note" }
        let(:limit) { 2 }

        it "appends the cap after the string" do
          expect(sql).to eq("SELECT '/*' AS note\nLIMIT 2")
        end
      end

      context "when a closed block comment spans lines" do
        let(:statement) { "SELECT 1 AS id\n/* note\n*/" }
        let(:limit) { 2 }

        it "appends the cap after the comment" do
          expect(sql).to eq("SELECT 1 AS id\n/* note\n*/\nLIMIT 2")
        end
      end

      context "when a block comment opener sits inside a dollar quote" do
        let(:statement) { "SELECT $$hello /* world$$ AS note" }

        it "appends the cap after the dollar quote" do
          expect(sql).to eq("SELECT $$hello /* world$$ AS note\nLIMIT 10000")
        end
      end

      context "when a dollar quote sits inside a string before a line comment" do
        let(:statement) { "SELECT '$$' AS a -- comment $$ LIMIT 1" }
        let(:limit) { 2 }

        it "appends the cap on the next line" do
          expect(sql).to eq("#{statement}\nLIMIT 2")
        end
      end
    end

    context "when the statement already ends with a limit" do
      let(:statement) { "SELECT 1 AS value LIMIT 15" }

      it "leaves a smaller limit unchanged" do
        expect(sql).to eq(statement)
      end

      context "with a trailing offset" do
        let(:statement) { "SELECT 1 AS value LIMIT 1 OFFSET 0" }

        it "leaves the offset unchanged" do
          expect(sql).to eq(statement)
        end
      end

      context "with a MySQL-style offset and count" do
        let(:statement) { "SELECT 1 AS value LIMIT 0, 1" }

        it "leaves the clause unchanged" do
          expect(sql).to eq(statement)
        end
      end

      context "with a trailing semicolon" do
        let(:statement) { "SELECT 1 AS value LIMIT 1;" }

        it "strips the semicolon and leaves the limit" do
          expect(sql).to eq("SELECT 1 AS value LIMIT 1")
        end
      end

      context "with a trailing line comment" do
        let(:statement) { "SELECT 1 AS value LIMIT 1 -- keep" }

        it "leaves the comment in place" do
          expect(sql).to eq(statement)
        end
      end

      context "when the existing limit is larger" do
        let(:statement) { "SELECT 1 AS value UNION ALL SELECT 2 LIMIT 100" }
        let(:limit) { 2 }

        it "rewrites the count in place" do
          expect(sql).to eq("SELECT 1 AS value UNION ALL SELECT 2 LIMIT 2")
        end
      end

      context "when a larger limit has an offset" do
        let(:statement) { "SELECT 1 AS value LIMIT 100 OFFSET 0" }
        let(:limit) { 2 }

        it "rewrites the count and keeps the offset" do
          expect(sql).to eq("SELECT 1 AS value LIMIT 2 OFFSET 0")
        end
      end

      context "when a MySQL count is larger" do
        let(:statement) { "SELECT 1 AS value LIMIT 0, 100" }
        let(:limit) { 2 }

        it "rewrites the count and keeps the offset" do
          expect(sql).to eq("SELECT 1 AS value LIMIT 0, 2")
        end
      end

      context "when the line has a quoted double dash" do
        let(:statement) { "SELECT 'a--b' AS note LIMIT 50" }

        it "leaves a smaller limit unchanged" do
          expect(sql).to eq(statement)
        end

        context "when that limit is larger than the cap" do
          let(:statement) { "SELECT 'a--b' AS note LIMIT 50000" }
          let(:limit) { 2 }

          it "rewrites the count in place" do
            expect(sql).to eq("SELECT 'a--b' AS note LIMIT 2")
            expect(sql.scan(/LIMIT/i).size).to eq(1)
          end
        end
      end

      context "when a double dash is inside a block comment" do
        let(:statement) { "SELECT 1 /* -- note */ LIMIT 50" }

        it "leaves a smaller limit unchanged" do
          expect(sql).to eq(statement)
        end
      end

      context "when a block comment opener sits inside a string" do
        let(:statement) { "SELECT '/*' AS note LIMIT 50000" }
        let(:limit) { 2 }

        it "rewrites the count in place" do
          expect(sql).to eq("SELECT '/*' AS note LIMIT 2")
          expect(sql.scan(/LIMIT/i).size).to eq(1)
        end
      end

      context "when a block comment opener sits inside a double-quoted string" do
        let(:statement) { 'SELECT "/*" AS note LIMIT 50000' }
        let(:limit) { 2 }

        it "rewrites the count in place" do
          expect(sql).to eq('SELECT "/*" AS note LIMIT 2')
          expect(sql.scan(/LIMIT/i).size).to eq(1)
        end
      end

      context "with a trailing block comment" do
        let(:statement) { "SELECT 1 AS value LIMIT 100 /* rest */" }
        let(:limit) { 2 }

        it "rewrites the count in place" do
          expect(sql).to eq("SELECT 1 AS value LIMIT 2 /* rest */")
          expect(sql.scan(/LIMIT/i).size).to eq(1)
        end
      end

      context "with a line comment glued to the count" do
        let(:statement) { "SELECT 1 AS value LIMIT 10--keep" }
        let(:limit) { 2 }

        it "rewrites the count in place" do
          expect(sql).to eq("SELECT 1 AS value LIMIT 2--keep")
          expect(sql.scan(/LIMIT/i).size).to eq(1)
        end
      end

      context "when a smaller limit has a trailing block comment" do
        let(:statement) { "SELECT 1 AS value LIMIT 1 /* note */" }

        it "leaves the clause unchanged" do
          expect(sql).to eq(statement)
          expect(sql.scan(/LIMIT/i).size).to eq(1)
        end
      end

      context "when a double dash sits inside a dollar quote" do
        let(:statement) { "SELECT $$a--b$$ AS note LIMIT 50" }

        it "leaves a smaller limit unchanged" do
          expect(sql).to eq(statement)
          expect(sql.scan(/LIMIT/i).size).to eq(1)
        end
      end

      context "when a tagged dollar quote hides a double dash" do
        let(:statement) { "SELECT $q$--$q$ AS note LIMIT 50000" }
        let(:limit) { 2 }

        it "rewrites the count in place" do
          expect(sql).to eq("SELECT $q$--$q$ AS note LIMIT 2")
          expect(sql.scan(/LIMIT/i).size).to eq(1)
        end
      end

      context "when a closed block comment spans lines before the limit" do
        let(:statement) { "SELECT 1 /* note\nstill */ LIMIT 5" }
        let(:limit) { 2 }

        it "rewrites the trailing count in place" do
          expect(sql).to eq("SELECT 1 /* note\nstill */ LIMIT 2")
          expect(sql.scan(/LIMIT/i).size).to eq(1)
        end
      end
    end
  end
end
