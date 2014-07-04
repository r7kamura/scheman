module SchemaManager
  module Parsers
    class Mysql < Base
      def self.parser
        @parser ||= Parser.new
      end

      def self.parse(schema)
        parser.parse(schema)
      end

      # @param schema [String]
      # @return [SchemaManager::Schema]
      def parse(schema)
        result = self.class.parse(schema)
        Schema.new(result)
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

        def quoted(value)
          str("`") >> value >> str("`")
        end

        def parenthetical(value)
          str("(") >> value >> str(")")
        end

        def comma_separated(value)
          value >> (str(",") >> value).repeat
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
          alter |
          #insert |
          delimiter_statement |
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

        rule(:something) do
          spaces >> match('[\S]').repeat >> spaces
        end

        rule(:string) do
          any.repeat(1)
        end

        rule(:name) do
          quoted(string) | string
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
          case_insensitive_str("drop table") >> non(delimiter) >> eol
        end

        rule(:create) do
          case_insensitive_str("create database") >> non(delimiter) >> eol
        end

        rule(:alter) do
          case_insensitive_str("alter table") >> something >> comma_separated(alter_specification) >> eol
        end

        rule(:alter_specification) do
          case_insensitive_str("add") >> spaces >> foreign_key_def
        end

        rule(:foreign_key_def) do
          foreign_key_def_begin >> spaces >> parens_field_list >> spaces >> reference_definition
        end

        rule(:foreign_key_def_begin) do
          (case_insensitive_str("constraint foreign key") >> something) |
            (case_insensitive_str("constraint") >> something >> case_insensitive_str("foreign key")) |
            (case_insensitive_str("foreign key") >> something) |
            (case_insensitive_str("foreign key"))
        end

        rule(:parens_field_list) do
          parenthetical(comma_separated(name))
        end

        # TODO: match_type.maybe >> on_delete.maybe >> on_update.maybe
        rule(:reference_definition) do
          case_insensitive_str("references") >> something >> parens_field_list.maybe
        end

        rule(:delimiter_statement) do
          case_insensitive_str("delimiter") >> non(delimiter)
        end

        rule(:empty_statement) do
          delimiter
        end
      end
    end
  end
end
