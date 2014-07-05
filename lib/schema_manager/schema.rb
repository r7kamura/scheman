module SchemaManager
  class Schema
    def initialize(raw)
      @raw = raw
      require "pp"
      pp raw
    end
  end
end
