module SchemaManager
  class Diff
    # @param before [String] The previous schema
    # @param after [String] The next schema
    # @param type [String] The type of schema syntax, default types of the both schemata (e.g. "mysql")
    # @param before_type [String] Specify the type of the previous schema if needed
    # @param after_type [String] Specify the type of the next schema if needed
    # @param output_type [String] Specify the type of the output schema if needed
    # @raise [SchemaManager::Errors::ParserNotFound]
    def initialize(before: nil, after: nil, type: nil, before_type: nil, after_type: nil, output_type: nil)
      @before = before
      @after = after
      @type = type
      @before_type = before_type
      @after_type = after_type
      @output_type = output_type
      validate!
    end

    # @return [String] A string representation of this diff
    def to_s
      view_class.new(to_hash).to_s
    end

    # @note Passed to Parslet::Transform to convert into SQL string
    # @return [Hash] A hash representation of this diff
    def to_hash
      {
        alter_tables: alter_tables,
        create_tables: create_tables,
        drop_tables: drop_tables,
      }
    end

    private

    # TODO
    # @return [Array<Hash>] ALTER TABLE statements we need to apply
    def alter_tables
      after_schema.tables.each do |after_table|
        table_name = after_table[:name]
        if before_table = before_schema.tables_indexed_by_name[table_name]
        end
      end
      []
    end

    # @return [Array<Hash>] DROP TABLE statements we need to apply
    def drop_tables
      table_names_to_drop.map do |name|
        {
          drop_table: {
            name: name,
          },
        }
      end
    end

    # @return [Array<Hash>] CREATE TABLE statements we need to apply
    def create_tables
      after_schema.create_tables.select do |statement|
        table_names_to_create.include?(statement[:create_table][:name])
      end
    end

    # @return [Array<String>]
    def table_names_to_create
      @table_names_to_create ||= after_schema.table_names - before_schema.table_names
    end

    # @return [Array<String>]
    def table_names_to_drop
      @table_names_to_drop ||= before_schema.table_names - after_schema.table_names
    end

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

    # @return [String]
    def output_type
      @output_type || @type
    end

    # @return [Class]
    def view_class
      case output_type
      when "mysql"
        Views::Mysql
      else
        raise Errors::ViewNotFound
      end
    end
  end
end
