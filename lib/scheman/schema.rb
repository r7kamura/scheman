module Scheman
  class Schema
    def initialize(statements)
      @statements = statements
    end

    def to_hash
      @statements
    end

    # @return [Array<Hash>] An array of CREATE TABLE statements
    def create_tables
      @create_tables ||= @statements.select do |statement|
        statement[:create_table]
      end
    end

    # @return [Hash]
    def tables_indexed_by_name
      @tables_indexed_by_name ||= tables.index_by(&:name)
    end

    # TODO: We might want to calculate DROP TABLE and ALTER TABLE against to created tables
    # @return [Array<Scheman::Schema::Table>] All tables to be created after applying this schema
    def tables
      @tables ||= create_tables.map do |create_table|
        Table.new(create_table[:create_table])
      end
    end

    # @return [Array<String>]
    def table_names
      tables.map(&:name)
    end

    class Table
      def initialize(table)
        @table = table
      end

      # @return [String]
      def name
        @table[:name]
      end

      # @return [Array]
      def fields
        @table[:fields].map do |field|
          Field.new(field: field[:field], table: self)
        end
      end

      # @return [Hash]
      def fields_indexed_by_name
        @fields_indexed_by_name ||= fields.index_by(&:name)
      end
    end

    class Field
      def initialize(field: nil, table: nil)
        @field = field
        @table = table
      end

      # @note Overridden
      # @return [true, false]
      def ==(field)
        type == field.type && size == field.size && qualifiers == field.qualifiers
      end

      # @return [Hash]
      def to_hash
        @field.merge(qualifiers: qualifiers)
      end

      # @return [String]
      def name
        @field[:name]
      end

      # @return [String] Lower-cased type name
      # @example
      #   "varchar"
      def type
        @field[:type]
      end

      # @note Size can be 2 values but not supported yet
      # @return [String, nil]
      def size
        field[:size]
      end

      # @return [Array<Hash>] Sorted qualifiers, without primary_key
      def qualifiers
        @qualifiers ||= @field[:qualifiers].reject do |qualifier|
          qualifier[:qualifier][:type] == "primary_key"
        end
      end
    end
  end
end
