module SchemaManager
  class Schema
    def initialize(raw)
      @raw = raw
    end

    def to_hash
      @raw
    end
  end
end
