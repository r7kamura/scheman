module SchemaManager
  module Parsers
    class Mysql < Base
      def self.parser
        @parser ||= Parser.new
      end

      def self.parse(schema)
        parser.parse(schema)
      end

      # TODO
      # @param schema [String]
      def parse(schema)
        Schema.new
      end

      class Parser < Parslet::Parser
        # @return [Parslet::Atoms::Sequence] Case-insensitive pattern from a given string
        def case_insensitive_str(str)
          str.each_char.map {|char| match[char.downcase + char.upcase] }.reduce(:>>)
        end

        root(:statements)

        rule(:statements) do
          statement.repeat(1)
        end

        rule(:statement) do
          comment |
          use |
          #set |
          #drop |
          #create |
          #alter |
          #insert |
          #delimiter |
          empty_statement
        end

        rule(:newline) do
          str("\n") >> str("\r").maybe
        end

        rule(:space) do
          match('\s').repeat(1)
        end

        rule(:spaces) do
          space.repeat
        end

        rule(:spaces?) do
          spaces.maybe
        end

        rule(:delimiter) do
          str(";")
        end

        rule(:comment) do
          spaces? >> comment_prefix >> comment_body >> newline
        end

        rule(:comment_prefix) do
          str("#") | str("--")
        end

        rule(:comment_body) do
          (newline.absent? >> any).repeat
        end

        rule(:use) do
          user_in_case_insensitive >> (delimiter.absent? >> any).repeat >> delimiter >> spaces?
        end

        rule(:user_in_case_insensitive) do
          case_insensitive_str("use")
        end

        rule(:empty_statement) do
          delimiter
        end
      end
    end
  end
end
