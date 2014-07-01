module SchemaManager
  class Parser
    # @note TODO
    # @param str [String] A text of a parsed schema file
    # @return [SchemaManager::Schema]
    def parse(str)
      Schema.new
    end
  end
end
