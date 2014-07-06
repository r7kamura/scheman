module SchemaManager
  class Schema
    def initialize(statements)
      @statements = statements
    end

    def to_hash
      @statements
    end

    # @return [Array<Hash>] An array of table definitions created in this schema
    def created_tables
      @statements.inject([]) do |result, statement|
        if create_table = statement[:create_table]
          result << create_table
        else
          result
        end
      end
    end

    # TODO
    # @reutrn [Array<String>] An array of table names to created in this schema
    def created_table_names
      @statements.inject([]) do |result, statement|
        if create_table = statement[:create_table]
          result << create_table[:name]
        else
          result
        end
      end
    end
  end
end
