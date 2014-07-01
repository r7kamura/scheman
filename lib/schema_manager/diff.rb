module SchemaManager
  class Diff
    # @param before [String] The previous schema
    # @param after [String] The next schema
    # @param type [String] The type of schema syntax (e.g. "mysql")
    def initialize(before: nil, after: nil, type: nil)
      @before = before
      @after = after
      @type = type
      validate!
    end

    # @return [String] SQL applied for the previous to change to the next
    def to_s
      "TODO"
    end

    private

    # @return [SchemaManager::Schema]
    def before_schema
      @before_schema ||= parser.parse(@before)
    end

    # @return [SchemaManager::Schema]
    def after_schema
      @after_schema ||= parser.parse(@after)
    end

    # @return [SchemaManager::Parsers::Base]
    # @raise [SchemaManager::Errors::ParserNotFound]
    def parser
      @parser ||= ParserBuilder.build(@type)
    end

    # @raise [SchemaManager::Errors::ParserNotFound]
    def validate!
      parser
    end
  end
end
