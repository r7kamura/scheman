module SchemaManager
  class Diff
    # @param before [String] The previous schema
    # @param after [String] The next schema
    # @param type [String] The type of schema syntax, default types of the both schemata (e.g. "mysql")
    # @param before_type [String] Specify the type of the previous schema if needed
    # @param after_type [String] Specify the type of the next schema if needed
    # @raise [SchemaManager::Errors::ParserNotFound]
    def initialize(before: nil, after: nil, type: nil, before_type: nil, after_type: nil)
      @before = before
      @after = after
      @type = type
      @before_type = before_type
      @after_type = after_type
      validate!
    end

    # @return [String] SQL applied for the previous to change to the next
    def to_s
      "TODO"
    end

    private

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
  end
end
