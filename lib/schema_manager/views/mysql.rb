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

        rule(create_tables: sequence(:create_tables)) do
          CreateTables.new(create_tables)
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
      end

      class Node
        def initialize(element)
          @element = element
        end
      end

      class CreateTables < Node
        def to_s
          @element.join("\n\n")
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
