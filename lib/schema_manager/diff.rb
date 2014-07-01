module SchemaManager
  class Diff
    # @param before [String] The previous schema
    # @param after [String] The next schema
    # @param type [String] The type of schema syntax (e.g. "mysql")
    def initialize(before: nil, after: nil, type: nil)
      @before = before
      @after = after
      @type = type
    end

    # @return [String] SQL applied for the previous to change to the next
    def to_s
      "TODO"
    end
  end
end
