# frozen_string_literal: true

module Nquery
  module DataSources
    # Applies a row cap to a user statement without emitting a second LIMIT.
    class RowLimit
      def self.apply(statement, limit)
        new(statement, limit).apply
      end

      def initialize(statement, limit)
        @statement = statement.to_s.strip.sub(/;\s*\z/, "")
        @limit = limit.to_i
      end

      def apply
        scan = Scan.new(@statement)
        prefix, suffix = split_unclosed_comment(scan)
        clause = TrailingClause.find(prefix, scan)
        sql = capped_sql(prefix, suffix, clause)
        # SQLite does not tokenize a terminal /* as a comment unless another character follows.
        return sql unless sql.end_with?("/*")

        "#{sql}\n"
      end

      private

      def capped_sql(prefix, suffix, clause)
        return append_limit(prefix, suffix) if clause.blank?
        return @statement unless clause.exceeds?(@limit)

        "#{clause.rewrite(@limit)}#{suffix}"
      end

      def append_limit(prefix, suffix)
        capped = "#{prefix.rstrip}\nLIMIT #{@limit}"
        return capped if suffix.empty?

        "#{capped} #{suffix.lstrip}"
      end

      def split_unclosed_comment(scan)
        index = scan.unclosed_comment_index
        return [@statement, ""] unless index

        [@statement[0...index], @statement[index..]]
      end

      # One left-to-right pass. A /* or $$ inside a string or comment is not an opener.
      class Scan
        DOLLAR_TAG = /\A\$(?:[A-Za-z_][A-Za-z0-9_]*)?\$/
        private_constant :DOLLAR_TAG

        def initialize(statement)
          @statement = statement
          @index = 0
          @length = statement.length
          @unclosed_comment_index = nil
          @line_comments = []
          advance
        end

        attr_reader :unclosed_comment_index

        def inside_line_comment?(position)
          @line_comments.any? { |range| range.cover?(position) }
        end

        private

        def advance
          while @index < @length
            next if skip_token

            @index += 1
          end
        end

        def skip_token
          consume_block_comment || consume_line_comment || consume_single_quote ||
            consume_double_quote || consume_dollar_quote
        end

        def consume_block_comment
          return false unless starts_with?("/*")

          close_at = @statement.index("*/", @index + 2)
          if close_at
            @index = close_at + 2
          else
            @unclosed_comment_index = @index
            @index = @length
          end
          true
        end

        def consume_line_comment
          return false unless starts_with?("--")

          finish = @statement.index("\n", @index) || @length
          @line_comments << (@index...finish)
          @index = finish < @length ? finish + 1 : finish
          true
        end

        def consume_single_quote
          return false unless @statement[@index] == "'"

          @index += 1
          while @index < @length
            if @statement[@index] == "'" && @statement[@index + 1] == "'"
              @index += 2
            elsif @statement[@index] == "'"
              @index += 1
              break
            else
              @index += 1
            end
          end
          true
        end

        def consume_double_quote
          return false unless @statement[@index] == '"'

          @index += 1
          while @index < @length
            if @statement[@index] == "\\"
              @index += 2
            elsif @statement[@index] == '"'
              @index += 1
              break
            else
              @index += 1
            end
          end
          true
        end

        def consume_dollar_quote
          return false unless @statement[@index] == "$"

          tag = @statement[@index..].match(DOLLAR_TAG)
          return false unless tag

          close_at = @statement.index(tag[0], @index + tag[0].length)
          @index = close_at ? close_at + tag[0].length : @length
          true
        end

        def starts_with?(token)
          @statement[@index, token.length] == token
        end
      end
      private_constant :Scan

      # A trailing LIMIT / OFFSET that is real SQL, not a limit hidden by `--`.
      class TrailingClause
        PATTERN = %r{
          \sLIMIT\s+
          (?:
            \d+\s*,\s*(?<mysql_count>\d+)
            |
            (?<count>\d+)(?:\s+OFFSET\s+\d+)?
          )
          (?:
            \s*/\*.*?\*/
            |
            \s*--[^\n]*
          )?
          \s*\z
        }ix
        private_constant :PATTERN

        def self.find(statement, scan)
          match = statement.match(PATTERN)
          return unless match
          return if scan.inside_line_comment?(match.begin(0))

          new(statement, match)
        end

        def initialize(statement, match)
          @statement = statement
          @match = match
        end

        def exceeds?(limit)
          count > limit
        end

        def rewrite(limit)
          start_at = @match.begin(count_key)
          "#{@statement[0...start_at]}#{limit}#{@statement[@match.end(count_key)..]}"
        end

        private

        def count
          @match[count_key].to_i
        end

        def count_key
          @match[:mysql_count] ? :mysql_count : :count
        end
      end
      private_constant :TrailingClause
    end
  end
end
