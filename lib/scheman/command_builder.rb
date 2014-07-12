module Scheman
  class CommandBuilder
    def self.call(*args)
      new(*args).call
    end

    # @param argv [Array] ARGV
    def initialize(argv)
      @argv = argv
    end

    # @return [Scheman::Commands::Base]
    def call
      command_class.new(@argv)
    rescue Errors::CommandNotFound
      terminate
    end

    private

    def command_class
      case command_name
      when "diff"
        Commands::Diff
      else
        raise Errors::CommandNotFound
      end
    end

    # @note You must pass a command name like "scheman diff"
    def command_name
      @argv[0]
    end

    def usage
      "Usage: #{$0} <command> [options]"
    end

    def terminate
      warn usage
      exit(1)
    end
  end
end
