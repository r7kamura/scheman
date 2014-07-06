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
        self.class.transform.apply(@diff)
      end

      class Transform < Parslet::Transform
        rule(create_tables: sequence(:create_tables)) do
          statements = create_tables.dup
          statements.unshift("BEGIN;")
          statements.push("COMMIT;")
          statements.join("\n\n") + "\n"
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

      class Tree
        def initialize(tree)
          @tree = tree
        end
      end

      class CreateTable < Tree
        def to_s
          str = ""
          str << "CREATE TABLE `#{table_name}` (\n"
          str << definitions.join(",\n").indent(2) + "\n"
          str << ");"
        end

        private

        def table_name
          @tree[:name]
        end

        def definitions
          @tree[:fields] + @tree[:indices]
        end
      end

      class Field < Tree
        def to_s
          str = "`#{name}` #{type}"
          str << " #{qualifiers}" if has_qualifiers?
          str
        end

        private

        # @example
        #   "id"
        def name
          @tree[:name]
        end

        # @example
        #   "INTEGER"
        def type
          @tree[:type].upcase
        end

        def qualifiers
          @tree[:qualifiers].map(&:to_s).join(" ")
        end

        def has_qualifiers?
          !@tree[:qualifiers].empty?
        end
      end

      class Qualifier < Tree
        def to_s
          str = type
          str << " #{value}" if has_value?
          str
        end

        private

        # @example
        #   "NOT NULL"
        def type
          @tree[:type].upcase.gsub("_", " ")
        end

        # @example
        #   "utf8"
        def value
          @tree[:value]
        end

        def has_value?
          @tree[:value]
        end
      end

      class Index < Tree
        def to_s
          "#{prefix} (`#{column}`)"
        end

        def primary_key?
          !!@tree[:primary]
        end

        def fulltext?
          @tree[:type] == "fulltext"
        end

        def spatial?
          @tree[:type] == "spatial"
        end

        # @example
        #   "id"
        def column
          @tree[:column]
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
