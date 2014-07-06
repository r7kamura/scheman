module SchemaManager
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
    # @return [Array<SchemaManager::Schema::Table>] All tables to be created after applying this schema
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
          Field.new(field[:field])
        end
      end

      # @return [Hash]
      def fields_indexed_by_name
        @fields_indexed_by_name ||= fields.index_by(&:name)
      end
    end

    class Field
      def initialize(field)
        @field = field
      end

      # @return [String]
      def name
        @field[:name]
      end

      # @return [Hash]
      def to_hash
        @field
      end
    end
  end
end
