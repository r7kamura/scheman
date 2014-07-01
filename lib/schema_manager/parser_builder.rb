module SchemaManager
  class ParserBuilder
    # @param type [String] A type of parser (e.g. "mysql")
    # @return [SchemaManager::Parsers::Base]
    def self.build(type)
      new(type).build
    end

    # @param type [String]
    def initialize(type)
      @type = type
    end

    def build
      parser_class.new
    end

    private

    def parser_class
      case @type
      when "mysql"
        Parsers::Mysql
      else
        raise Errors::ParserNotFound
      end
    end
  end
end
