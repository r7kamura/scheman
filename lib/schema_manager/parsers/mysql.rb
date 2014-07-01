module SchemaManager
  module Parsers
    class Mysql < Base
      def self.parser
        @parser ||= Parser.new
      end

      def self.parse(schema)
        parser.parse(schema)
      end

      # TODO
      # @param schema [String]
      def parse(schema)
        Schema.new
      end

      class Parser < Parslet::Parser
        root(:statement)

        rule(:statement) do
          comment |
          #use |
          #set |
          #drop |
          #create |
          #alter |
          #insert |
          #delimiter |
          empty_statement
        end

        rule(:newline) do
          str("\n") >> str("\r").maybe
        end

        rule(:space) do
          match('\s').repeat(1)
        end

        rule(:spaces) do
          space.repeat
        end

        rule(:spaces?) do
          spaces.maybe
        end

        rule(:comment) do
          spaces? >> comment_prefix >> comment_body >> newline
        end

        rule(:comment_prefix) do
          str("#") | str("--")
        end

        rule(:comment_body) do
          (newline.absent? >> any).repeat
        end

        rule(:empty_statement) do
          str(";") >> spaces?
        end
      end
    end
  end
end
