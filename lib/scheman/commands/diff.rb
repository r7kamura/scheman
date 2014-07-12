module Scheman
  module Commands
    class Diff < Base
      DEFAULT_AFTER_SCHEMA_PATH = "schema.sql"

      # @param argv [Array] ARGV
      def initialize(argv)
        @argv = argv
      end

      # Outputs a schema diff
      def call
        print diff
      end

      private

      def before
        case
        when has_input_from_stdin?
          STDIN.read
        when before_schema_path
          File.read(before_schema_path)
        else
          raise Errors::NoBeforeSchema
        end
      end

      def after
        case
        when after_schema_path
          File.read(after_schema_path)
        when has_default_schema_file?
          default_schema
        else
          "CREATE DATABASE database_name;"
        end
      end

      # @return [String]
      # @example
      #   "mysql"
      def type
        options[:type]
      end

      # @return [Schema::Diff]
      def diff
        @diff ||= Scheman::Diff.new(
          before: before,
          after: after,
          type: type,
        )
      end

      # @return [true, false] True if any input given via STDIN
      def has_input_from_stdin?
        has_pipe_input? || has_redirect_input?
      end

      # @return [true, false] True if any input given from redirection
      def has_pipe_input?
        File.pipe?(STDIN)
      end

      # @return [true, false] True if any input given from redirection
      def has_redirect_input?
        File.select([STDIN], [], [], 0) != nil
      end

      # @return [String, nil] Path to a previous schema
      def before_schema_path
        options[:before]
      end

      # @return [String, nil] Path to a next schema
      def after_schema_path
        options[:after]
      end

      # @return [String, nil] True if a schema file exists in the default schema file path
      def has_default_schema_file?
        File.exist?(DEFAULT_AFTER_SCHEMA_PATH)
      end

      # @return [String, nil]
      def default_schema
        File.read(DEFAULT_AFTER_SCHEMA_PATH)
      end

      def options
        @options ||= Slop.parse!(@argv, help: true) do
          banner "Usage: #{$0} diff [options]"
          on "type=", "SQL type (e.g. mysql)"
          on "before=", "Path to the previous schema file"
          on "after=", "Path to the next schema file"
        end
      end
    end
  end
end
