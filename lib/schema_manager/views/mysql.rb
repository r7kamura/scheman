module SchemaManager
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

      class AlterTables < Statements
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
        def to_s
          "TODO"
        end
      end

      class AddField < Node
        def to_s
          "ALTER TABLE `#{table_name}` ADD COLUMN #{field};"
        end

        private

        def table_name
          @element[:table_name]
        end

        def field
          Field.new(@element)
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

        def has_qualifiers?
          !@element[:qualifiers].empty?
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
    end
  end
end
