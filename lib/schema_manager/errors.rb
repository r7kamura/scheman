module SchemaManager
  module Errors
    class Base < StandardError
    end

    class ParserNotFound < Base
    end

    class ViewNotFound < Base
    end
  end
end
