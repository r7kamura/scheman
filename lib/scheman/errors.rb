module Scheman
  module Errors
    class Base < StandardError
    end

    class ParserNotFound < Base
    end

    class ViewNotFound < Base
    end

    class CommandNotFound < Base
    end

    class NoBeforeSchema < Base
    end
  end
end
