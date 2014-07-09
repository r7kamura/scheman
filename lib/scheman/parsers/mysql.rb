module Scheman
  module Parsers
    class Mysql < Base
      def self.parser
        @parser ||= ParsletParser.new
      end

      def self.transform
        @transform ||= ParsletTransform.new
      end

      # @param schema [String]
      # @return [Scheman::Schema]
      def self.parse(schema)
        Schema.new(
          transform.apply(
            parser.parse(
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
          value >> (str(",") >> spaces? >> value).repeat
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
          space.repeat(1)
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

        rule(:word_index) do
          case_insensitive_str("key") | case_insensitive_str("index")
        end

        rule(:create_table) do
          create_table_beginning >> spaces >> table_name >>
            spaces? >> table_components >> eol
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
          index | field | comment
        end

        rule(:index) do
          (
            primary_key |
            unique_key |
            foreign_key |
            normal_index |
            fulltext_index |
            spatial_index
          ).as(:index)
        end

        rule(:primary_key) do
          (
            case_insensitive_str("primary key") >>
              optional_index_type >>
              spaces >> parenthetical(comma_separated(column_name_with_optional_values)) >>
              optional_index_type
          ).as(:primary_key)
        end

        rule(:optional_index_type) do
          (spaces >> index_type).maybe
        end

        rule(:unique_key) do
          str("TODO")
        end

        rule(:foreign_key) do
          str("TODO")
        end

        rule(:normal_index) do
          word_index >> spaces >> index_name >>
            optional_using_index_type >>
            spaces >> parenthetical(comma_separated(column_name_with_optional_values)) >>
            optional_using_index_type
        end

        rule(:optional_using_index_type) do
          (spaces >> using_index_type).maybe
        end

        rule(:using_index_type) do
          case_insensitive_str("using") >> spaces >> index_type
        end

        rule(:index_name) do
          identifier.as(:index_name)
        end

        # TODO: Fix spaces not to allow no space
        rule(:fulltext_index) do
          (
            case_insensitive_str("fulltext") >> spaces >>
              (word_index >> spaces).maybe >>
              (index_name >> spaces).maybe >>
              parenthetical(comma_separated(column_name_with_optional_values))
          ).as(:fulltext_index)
        end

        rule(:spatial_index) do
          (
            case_insensitive_str("spatial") >> spaces >>
              (word_index >> spaces).maybe >>
              (index_name >> spaces).maybe >>
              parenthetical(comma_separated(column_name_with_optional_values))
          ).as(:spatial_index)
        end

        rule(:field) do
          (
            comment.repeat >> field_name.as(:field_name) >> spaces >> field_type >>
              (spaces >> field_qualifiers).maybe.as(:field_qualifiers) >>
              (spaces >> field_comment).maybe >>
              (spaces >> reference_definition).maybe >>
              (spaces >> on_update).maybe >>
              comment.maybe
          ).as(:field)
        end

        rule(:field_name) do
          quoted_identifier | identifier
        end

        rule(:field_qualifiers) do
          (field_qualifier >> (spaces >> field_qualifier).repeat)
        end

        # TODO: default value, on update
        rule(:field_qualifier) do
          not_null_qualifier |
            null_qualifier |
            primary_key_qualifier |
            auto_increment_qualifier |
            character_set_qualifier |
            collate_qualifier |
            unique_key_qualifier
        end

        rule(:unique_key_qualifier) do
          (case_insensitive_str("unique ") >> word_index).as(:unique_key_qualifier)
        end

        rule(:collate_qualifier) do
          (case_insensitive_str("collate") >> spaces >> identifier).as(:collate_qualifier)
        end

        rule(:character_set_qualifier) do
          (case_insensitive_str("character set") >> spaces >> identifier).as(:character_set_qualifier)
        end

        rule(:primary_key_qualifier) do
          (word_index | case_insensitive_str("primary key")).as(:primary_key_qualifier)
        end

        rule(:null_qualifier) do
          case_insensitive_str("null").as(:null_qualifier)
        end

        rule(:not_null_qualifier) do
          case_insensitive_str("not null").as(:not_null_qualifier)
        end

        rule(:auto_increment_qualifier) do
          case_insensitive_str("auto increment").as(:auto_increment_qualifier)
        end

        rule(:field_comment) do
          case_insensitive_str("comment") >> spaces >> single_quoted(match("[^']"))
        end

        rule(:on_update) do
          str("TODO")
        end

        rule(:field_type) do
          field_type_name >>
            (spaces? >> parenthetical(comma_separated(field_value))).maybe.as(:field_values) >>
            (spaces >> type_qualifier).repeat
        end

        rule(:field_value) do
          value.as(:field_value)
        end

        rule(:field_type_name) do
          identifier.as(:field_type_name)
        end

        rule(:type_qualifier) do
          case_insensitive_str("binary") | case_insensitive_str("unsigned") | case_insensitive_str("zerofill")
        end

        rule(:column_name_with_optional_values) do
          column_name >> (spaces? >> parenthetical(comma_separated(value))).maybe
        end

        rule(:column_name) do
          quoted_identifier.as(:column_name)
        end

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
          (
            case_insensitive_str("btree") | case_insensitive_str("hash") | case_insensitive_str("rtree")
          ).as(:index_type)
        end

        rule(:identifier) do
          match('\w').repeat(1).as(:identifier)
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
        # @example
        # [
        #   { ... },
        #   { ... }
        # ]
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
        # "utf8"
        rule(identifier: simple(:identifier)) do
          identifier.to_s
        end

        rule(field_value: simple(:field_value)) do
          field_value.to_s
        end

        rule(
          field_type_name: simple(:field_type_name),
          field_name: simple(:field_name),
          field_qualifiers: subtree(:field_qualifiers),
          field_values: subtree(:field_values),
        ) do
          {
            name: field_name.to_s,
            type: field_type_name.to_s.downcase,
            qualifiers: Array.wrap(field_qualifiers).map do |qualifier|
              { qualifier: qualifier }
            end,
            values: Array.wrap(field_values),
          }
        end

        rule(table_name: simple(:table_name), table_components: subtree(:table_components)) do
          components = Array.wrap(table_components)

          fields = components.select do |component|
            component[:field]
          end.compact

          indices = components.select do |component|
            component[:index]
          end.compact

          {
            name: table_name,
            fields: fields,
            indices: indices,
          }
        end

        rule(auto_increment_qualifier: simple(:auto_increment_qualifier)) do
          {
            type: "auto_increment",
          }
        end

        rule(not_null_qualifier: simple(:not_null_qualifier)) do
          {
            type: "not_null",
          }
        end

        rule(null_qualifier: simple(:null_qualifier)) do
          {
            type: "null",
          }
        end

        rule(primary_key_qualifier: simple(:primary_key_qualifier)) do
          {
            type: "primary_key",
          }
        end

        rule(character_set_qualifier: simple(:character_set_qualifier)) do
          {
            type: "character_set",
            value: character_set_qualifier,
          }
        end

        rule(collate_qualifier: simple(:collate_qualifier)) do
          {
            type: "collate",
            value: collate_qualifier,
          }
        end

        rule(unique_key_qualifier: simple(:unique_key_qualifier)) do
          {
            type: "unique_key",
          }
        end

        rule(key_qualifier: simple(:key_qualifier)) do
          {
            type: "key",
          }
        end

        rule(database_name: simple(:database_name)) do
          {
            database_name: database_name.to_s,
          }
        end

        rule(primary_key: subtree(:primary_key)) do
          primary_key.merge(primary: true)
        end

        rule(fulltext_index: subtree(:fulltext_index)) do
          fulltext_index.merge(type: "fulltext")
        end

        rule(spatial_index: subtree(:spatial_index)) do
          spatial_index.merge(type: "spatial")
        end

        rule(column_name: simple(:column_name)) do
          {
            column: column_name,
            name: nil,
            type: nil,
          }
        end

        rule(
          column_name: simple(:column_name),
          index_type: simple(:index_type),
        ) do
          {
            column: column_name,
            name: nil,
            type: index_type.try(:to_s).try(:downcase),
          }
        end

        rule(
          column_name: simple(:column_name),
          index_name: simple(:index_name),
        ) do
          {
            column: column_name,
            name: index_name,
            type: nil,
          }
        end

        rule(
          column_name: simple(:column_name),
          index_name: simple(:index_name),
          index_type: simple(:index_type),
        ) do
          {
            column: column_name,
            name: index_name,
            type: index_type.try(:to_s).try(:downcase),
          }
        end
      end
    end
  end
end
