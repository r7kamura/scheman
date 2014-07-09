module Scheman
  module Views
    class Mysql < Base
      def self.transform
        @transform ||= Transform.new
      end

      # @param diff [Hash]
      def initialize(diff)
        @diff = diff
      end

      # @return [String]
      def to_s
        self.class.transform.apply(
          root: @diff
        )
      end

      class Transform < Parslet::Transform
        rule(root: subtree(:root)) do
          [
            "BEGIN;",
            "SET foreign_key_checks=0;",
            root,
            "SET foreign_key_checks=1;",
            "COMMIT;",
          ].join("\n\n") + "\n"
        end

        rule(
          alter_tables: sequence(:alter_tables),
          create_tables: sequence(:create_tables),
          drop_tables: sequence(:drop_tables),
        ) do
          [
            CreateTables.new(create_tables).to_s.presence,
            AlterTables.new(alter_tables).to_s.presence,
            DropTables.new(drop_tables).to_s.presence,
          ].compact.join("\n\n")
        end

        rule(drop_table: subtree(:drop_table)) do
          DropTable.new(drop_table)
        end

        rule(create_table: subtree(:create_table)) do
          CreateTable.new(create_table)
        end

        rule(field: subtree(:field)) do
          Field.new(field)
        end

        rule(qualifier: subtree(:qualifier)) do
          Qualifier.new(qualifier)
        end

        rule(index: subtree(:index)) do
          Index.new(index)
        end

        rule(add_field: subtree(:add_field)) do
          AddField.new(add_field)
        end

        rule(drop_field: subtree(:drop_field)) do
          DropField.new(drop_field)
        end

        rule(alter_field: subtree(:alter_field)) do
          AlterField.new(alter_field)
        end

        rule(add_index: subtree(:add_index)) do
          AddIndex.new(add_index)
        end

        rule(drop_index: subtree(:drop_index)) do
          DropIndex.new(drop_index)
        end

        rule(default_value: subtree(:tree)) do
          DefaultValue.new(tree)
        end
      end

      class Node
        def initialize(element)
          @element = element
        end
      end

      class Statements < Node
        def to_s
          @element.join("\n\n")
        end
      end

      class AlterTables < Node
        def to_s
          alter_tables.join("\n\n")
        end

        private

        def alter_tables
          @element.group_by(&:table_name).map do |table_name, alter_tables|
            %<ALTER TABLE `#{table_name}` #{alter_tables.join(",\n  ")};>
          end.sort
        end
      end

      class DropTables < Statements
      end

      class CreateTables < Statements
      end

      class DropTable < Node
        def to_s
          "DROP TABLE `#{table_name}`;"
        end

        private

        def table_name
          @element[:name]
        end
      end

      class AlterTable < Node
        def table_name
          @element[:table_name]
        end
      end

      class AlterField < AlterTable
        def to_s
          "CHANGE COLUMN #{field_definition}"
        end

        private

        def field_definition
          Field.new(@element)
        end
      end

      class AddField < AlterTable
        def to_s
          "ADD COLUMN #{field_definition}"
        end

        private

        def field_definition
          Field.new(@element)
        end
      end

      class DropField < AlterTable
        def to_s
          "DROP COLUMN `#{field_name}`"
        end

        private

        def field_name
          @element[:name]
        end
      end

      class AddIndex < AlterTable
        def to_s
          "ADD #{index_definition_name} #{index}"
        end

        private

        def index_name
          @element[:name]
        end

        def index_definition_name
          case
          when @element[:primary]
            "PRIMARY KEY"
          when @element[:unique]
            "UNIQUE KEY"
          else
            "KEY"
          end
        end

        def index_type
          @element[:type]
        end

        def index_column
          @element[:column]
        end

        def index
          str = ""
          str << "#{index_name} " if index_name
          str << "#{index_type} " if index_type
          str << "`#{index_column}`"
        end
      end

      class DropIndex < AlterTable
        def to_s
          if @element[:primary]
            "DROP PRIMARY KEY"
          else
            "DROP INDEX `#{index_name}`"
          end
        end

        private

        # TODO How to refer to an automatically named index name?
        def index_name
          @element[:name] || @element[:column]
        end
      end

      class CreateTable < Node
        def to_s
          str = ""
          str << "CREATE TABLE `#{table_name}` (\n"
          str << definitions.join(",\n").indent(2) + "\n"
          str << ");"
        end

        private

        def table_name
          @element[:name]
        end

        def definitions
          @element[:fields] + @element[:indices]
        end
      end

      class Field < Node
        def to_s
          str = "`#{name}` #{type}"
          str << "(#{values})" if has_values?
          str << " #{qualifiers}" if has_qualifiers?
          str
        end

        private

        # @example
        #   "id"
        def name
          @element[:name]
        end

        # @example
        #   "INTEGER"
        def type
          @element[:type].upcase
        end

        def qualifiers
          @element[:qualifiers].map(&:to_s).join(" ")
        end

        def values
          @element[:values].join(", ")
        end

        def has_qualifiers?
          !@element[:qualifiers].empty?
        end

        def has_values?
          !@element[:values].empty?
        end
      end

      class Qualifier < Node
        def to_s
          str = type
          str << " #{value}" if has_value?
          str
        end

        private

        # @example
        #   "NOT NULL"
        def type
          @element[:type].upcase.gsub("_", " ")
        end

        # @example
        #   "utf8"
        def value
          @element[:value]
        end

        def has_value?
          @element[:value]
        end
      end

      class Index < Node
        def to_s
          "#{prefix} (`#{column}`)"
        end

        def primary_key?
          !!@element[:primary]
        end

        def fulltext?
          @element[:type] == "fulltext"
        end

        def spatial?
          @element[:type] == "spatial"
        end

        # @example
        #   "id"
        def column
          @element[:column]
        end

        # @example
        #   "PRIMARY KEY"
        def prefix
          case
          when primary_key?
            "PRIMARY KEY"
          when fulltext?
            "FULLTEXT"
          when spatial?
            "SPATIAL"
          else
            "KEY"
          end
        end
      end

      class DefaultValue < Node
        def to_s
          case @element[:type]
          when "string"
            @element[:value].inspect
          when "current_timestamp"
            "CURRENT_TIMESTAMP()"
          else
            @element[:value]
          end
        end
      end
    end
  end
end
