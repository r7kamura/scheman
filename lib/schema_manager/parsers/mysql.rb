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

        # @return [Parslet::Atoms::Repetation]
        def non(sequence)
          (sequence.absent? >> any).repeat
        end

        root(:statements)

        rule(:statements) do
          statement.repeat(1)
        end

        rule(:statement) do
          comment |
          use |
          set |
          drop |
          create |
          #alter |
          #insert |
          #delimiter |
          empty_statement
        end

        rule(:newline) do
          str("\n") >> str("\r").maybe
        end

        rule(:space) do
          match('\s')
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

        rule(:eol) do
          delimiter >> spaces?
        end

        rule(:comment) do
          (str("#") | str("--")) >> non(newline) >> newline >> spaces?
        end

        rule(:use) do
          case_insensitive_str("use") >> non(delimiter) >> eol
        end

        rule(:set) do
          case_insensitive_str("set") >> non(delimiter) >> eol
        end

        rule(:drop) do
          case_insensitive_str("drop") >> str(" TABLE") >> non(delimiter) >> eol
        end

        rule(:create) do
          str("CREATE ") >> case_insensitive_str("database") >> spaces >> non(delimiter) >> eol
        end

        rule(:empty_statement) do
          delimiter
        end
      end
    end
  end
end
