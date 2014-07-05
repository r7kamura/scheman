module SchemaManager
  module Parsers
    class Mysql < Base
      def self.parslet_parser
        @parslet_parser ||= ParsletParser.new
      end

      def self.parslet_transform
        @parslet_transform ||= ParsletTransform.new
      end

      # @param schema [String]
      # @return [SchemaManager::Schema]
      def self.parse(schema)
        Schema.new(
          parslet_transform.apply(
            parslet_parser.parse(
              schema
            )
          )
        )
      end

      def parse(schema)
        self.class.parse(schema)
      end

      class ParsletParser < Parslet::Parser
        # @return [Parslet::Atoms::Sequence] Case-insensitive pattern from a given string
        def case_insensitive_str(str)
          str.each_char.map {|char| match[char.downcase + char.upcase] }.reduce(:>>)
        end

        # @return [Parslet::Atoms::Repetation]
        def non(sequence)
          (sequence.absent? >> any).repeat
        end

        def quoted(value)
          single_quoted(value) | double_quoted(value) | back_quoted(value)
        end

        def quoted_string
          single_quoted(non(str("'"))) | double_quoted(non(str('"'))) | back_quoted(non(str("`")))
        end

        def single_quoted(value)
          str("'") >> value >> str("'")
        end

        def double_quoted(value)
          str('"') >> value >> str('"')
        end

        def back_quoted(value)
          str("`") >> value >> str("`")
        end

        def parenthetical(value)
          str("(") >> spaces? >> value >> spaces? >> str(")")
        end

        def comma_separated(value)
          value >> (str(",") >> spaces >> value).repeat
        end

        root(:statements)

        rule(:statements) do
          statement.repeat(1).as(:statements)
        end

        rule(:statement) do
          comment |
          use |
          set |
          drop |
          create_database |
          create_table.as(:create_table) |
          alter |
          insert |
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

        rule(:eol) do
          delimiter >> spaces?
        end

        rule(:comment) do
          (str("#") | str("--")) >> non(newline) >> newline >> spaces?
        end

        rule(:use) do
          case_insensitive_str("use") >> spaces >> non(delimiter).as(:database_name) >> eol
        end

        rule(:set) do
          case_insensitive_str("set") >> non(delimiter) >> eol
        end

        rule(:drop) do
          case_insensitive_str("drop table") >> non(delimiter) >> eol
        end

        rule(:create_database) do
          create_database_beginning >> non(delimiter) >> eol
        end

        rule(:create_database_beginning) do
          case_insensitive_str("create") >> str(" ") >> word_database
        end

        rule(:word_database) do
          case_insensitive_str("database") | case_insensitive_str("schema")
        end

        rule(:create_table) do
          create_table_beginning >> spaces >> table_name >>
            spaces >> table_components >> eol
        end

        rule(:table_components) do
          parenthetical(comma_separated(create_definition)).as(:table_components)
        end

        rule(:table_name) do
          (quoted_identifier | identifier).as(:table_name)
        end

        rule(:create_table_beginning) do
          case_insensitive_str("create") >> case_insensitive_str(" temporary").maybe >>
            case_insensitive_str(" table") >> case_insensitive_str(" if not exists").maybe
        end

        rule(:create_definition) do
          constraint | index | field | comment
        end

        rule(:constraint) do
          (primary_key_definition | unique_key_definition | foreign_key_definition).as(:constraint)
        end

        rule(:primary_key_definition) do
          (
            case_insensitive_str("primary key") >> (spaces >> index_type).maybe >>
              spaces >> parenthetical(comma_separated(name_with_optional_values)) >>
              (spaces >> index_type).maybe
          ).as(:primary_key)
        end

        rule(:unique_key_definition) do
          str("TODO")
        end

        rule(:foreign_key_definition) do
          str("TODO")
        end

        rule(:index) do
          str("TODO")
        end

        rule(:field) do
          (
            comment.repeat >> field_name.as(:field_name) >> spaces >> field_type >>
              (spaces >> field_qualifier).repeat >>
              (spaces >> field_comment).maybe >>
              (spaces >> reference_definition).maybe >>
              (spaces >> on_update).maybe >>
              comment.maybe
          ).as(:field)
        end

        rule(:field_name) do
          quoted_identifier | identifier
        end

        # TODO: default value, on update
        rule(:field_qualifier) do
          case_insensitive_str("not null") |
            case_insensitive_str("null") |
            case_insensitive_str("primary key") |
            case_insensitive_str("auto increment") |
            case_insensitive_str("unsigned") |
            case_insensitive_str("character set") >> spaces >> identifier |
            case_insensitive_str("collate") >> spaces >> identifier |
            case_insensitive_str("unique key") |
            case_insensitive_str("unique index") |
            case_insensitive_str("key") |
            case_insensitive_str("index")
        end

        rule(:field_comment) do
          case_insensitive_str("comment") >> spaces >> single_quoted(match("[^']"))
        end

        rule(:on_update) do
          str("TODO")
        end

        rule(:field_type) do
          field_type_name >>
            (spaces >> parenthetical(comma_separated(value))).repeat >>
            (spaces >> type_qualifier).repeat
        end

        rule(:field_type_name) do
          identifier.as(:field_type_name)
        end

        rule(:type_qualifier) do
          case_insensitive_str("binary") | case_insensitive_str("unsigned") | case_insensitive_str("zerofill")
        end

        rule(:name_with_optional_values) do
          quoted_identifier >> (spaces >> parenthetical(comma_separated(value))).maybe
        end

        # TODO: Replace string with another proper pattern
        rule(:value) do
          float_number | quoted_string | str("NULL")
        end

        rule(:float_number) do
          base_number >> exponent_number.maybe
        end

        rule(:sign) do
          match("[-+]")
        end

        rule(:unsigned_integer) do
          match('\d').repeat(1)
        end

        rule(:base_number) do
          sign.maybe >> str(".").maybe >> unsigned_integer
        end

        rule(:exponent_number) do
          match("e|E") >> unsigned_integer
        end

        rule(:index_type) do
          case_insensitive_str("btree") | case_insensitive_str("hash") | case_insensitive_str("rtree")
        end

        rule(:identifier) do
          match('\w').repeat(1)
        end

        rule(:quoted_identifier) do
          (
            single_quoted(match("[^']").repeat(1)) |
              double_quoted(match('[^"]').repeat(1)) |
              back_quoted(match("[^`]").repeat(1))
          ).as(:quoted_identifier)
        end

        rule(:insert) do
          case_insensitive_str("insert") >> non(delimiter) >> eol
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
            (case_insensitive_str("foreign key")) |
            (case_insensitive_str("foreign key") >> something)
        end

        rule(:parens_field_list) do
          parenthetical(comma_separated(match('[^)]').repeat(1)))
        end

        # TODO: match_type.maybe >> on_delete.maybe >> on_update.maybe
        rule(:reference_definition) do
          case_insensitive_str("references") >> non(delimiter) >> parens_field_list.maybe
        end

        rule(:delimiter_statement) do
          case_insensitive_str("delimiter") >> non(delimiter)
        end

        rule(:empty_statement) do
          delimiter
        end
      end

      class ParsletTransform < Parslet::Transform
        rule(statements: subtree(:statements)) do
          case statements
          when Array
            statements
          else
            []
          end
        end

        # @example
        # "id"
        rule(quoted_identifier: simple(:quoted_identifier)) do
          quoted_identifier.to_s.gsub(/\A`(.+)`\z/, '\1')
        end

        # @example
        # {
        #   name: "id",
        #   type: "integer"
        # }
        rule(field_type_name: simple(:field_type_name), field_name: simple(:field_name)) do
          {
            name: field_name.to_s,
            type: field_type_name.to_s.downcase,
          }
        end

        # @example
        # {
        #   name: "recipes",
        #   fields: [
        #     {
        #       name: "id",
        #       type: "integer"
        #     }
        #   ]
        # }
        rule(table_name: simple(:table_name), table_components: subtree(:table_components)) do
          fields = table_components.map do |component|
            component[:field]
          end.compact

          constraints = table_components.map do |component|
            component[:constraint]
          end.compact

          {
            name: table_name,
            fields: fields,
            constraints: constraints,
          }
        end
      end
    end
  end
end
