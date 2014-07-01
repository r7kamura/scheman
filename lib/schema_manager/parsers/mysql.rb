module SchemaManager
  module Parsers
    class Mysql < Base
      # TODO
      # @param schema [String]
      def parse(schema)
        Schema.new
      end
    end
  end
end
