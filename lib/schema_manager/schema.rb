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
      @tables_indexed_by_name ||= tables.inject({}) do |result, table|
        result.merge(table[:name] => table)
      end
    end

    # TODO: We might want to calculate DROP TABLE and ALTER TABLE against to created tables
    # @return [Array] All tables to be created after applying this schema
    def tables
      @tables ||= create_tables.map do |create_table|
        create_table[:create_table]
      end
    end

    # @return [Array<String>]
    def table_names
      tables.map {|table| table[:name] }
    end
  end
end
