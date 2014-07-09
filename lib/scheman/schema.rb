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

      # @return [Array<Field>]
      def fields
        @table[:fields].map do |field|
          Field.new(field: field[:field], table: self)
        end
      end

      # @return [Hash{String => Field}]
      def fields_indexed_by_name
        @fields_indexed_by_name ||= fields.index_by(&:name)
      end

      # @return [Array<Hash>]
      def indices
        @indices ||= indices_from_definitions + indices_from_fields
      end

      private

      def indices_from_definitions
        @table[:indices].map do |hash|
          hash[:index]
        end
      end

      # @return [Array<Hash>]
      def indices_from_fields
        fields.map(&:index).compact
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
        @field[:size]
      end

      # @return [Array<Hash>] Sorted qualifiers, without index-related types
      def qualifiers
        @qualifiers ||= @field[:qualifiers].reject do |qualifier|
          %w[primary_key unique_key].include?(qualifier[:qualifier][:type])
        end
      end

      # @return [Hash] Index defined as a field qualifier
      def index
        @field[:qualifiers].find do |qualifier|
          case qualifier[:qualifier][:type]
          when "primary_key"
            break {
              column: name,
              name: nil,
              primary: true,
              type: nil,
            }
          when "unique_key"
            break {
              column: name,
              name: nil,
              primary: nil,
              type: nil,
              unique: true,
            }
          end
        end
      end
    end
  end
end
