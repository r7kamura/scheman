module SchemaManager
  class Diff
    # @param before [String] The previous schema
    # @param after [String] The next schema
    # @param type [String] The type of schema syntax, default types of the both schemata (e.g. "mysql")
    # @param before_type [String] Specify the type of the previous schema if needed
    # @param after_type [String] Specify the type of the next schema if needed
    # @param output_type [String] Specify the type of the output schema if needed
    # @raise [SchemaManager::Errors::ParserNotFound]
    def initialize(before: nil, after: nil, type: nil, before_type: nil, after_type: nil, output_type: nil)
      @before = before
      @after = after
      @type = type
      @before_type = before_type
      @after_type = after_type
      @output_type = output_type
      validate!
    end

    # @return [String] SQL applied for the previous to change to the next
    def to_s
      "TODO"
    end

    # @return [Array<Hash>] An array of table definitions we need to create
    def tables_to_create
      after_schema.created_tables.select do |table|
        table_names_to_create.include?(table[:name])
      end
    end

    private

    # @note To be called from #tables_to_create
    # @return [Array<String>] An array of table names we need to create
    def table_names_to_create
      @table_names_to_create ||= after_schema.created_table_names - before_schema.created_table_names
    end

    # @return [SchemaManager::Schema]
    def before_schema
      @before_schema ||= before_parser.parse(@before)
    end

    # @return [SchemaManager::Schema]
    def after_schema
      @after_schema ||= after_parser.parse(@after)
    end

    # @return [SchemaManager::Parsers::Base]
    # @raise [SchemaManager::Errors::ParserNotFound]
    def before_parser
      @before_parser ||= ParserBuilder.build(before_type)
    end

    # @return [SchemaManager::Parsers::Base]
    # @raise [SchemaManager::Errors::ParserNotFound]
    def after_parser
      @after_parser ||= ParserBuilder.build(after_type)
    end

    # @raise [SchemaManager::Errors::ParserNotFound]
    def validate!
      before_parser
      after_parser
    end

    # @return [String]
    def before_type
      @before_type || @type
    end

    # @return [String]
    def after_type
      @after_type || @type
    end

    # @return [String]
    def output_type
      @output_type || @type
    end
  end
end
