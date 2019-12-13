class CLI
  EXIT_STATUS_SUCCSESS = 0
  EXIT_STATUS_ERR = 2

  def self.start(argv)
    new(argv).start
  end

  def initialize(argv)
    @argv = argv
    @error_queue = Thread::Queue.new
    @exit_status = EXIT_STATUS_SUCCSESS
    @debug = ENV['RUBOCOP_REGRESSION_TEST_DEBUG']
  end

  def start

    usage! unless subcommand

    case subcommand
    when 'check'
      command_check
    when 'config'
      command_config
    else
      usage!
    end
  end

  attr_reader :argv, :error_queue, :debug
  private :argv, :error_queue, :debug

  private def command_check
    th = watch_error_queue
    CircleCI.start
    run_for(args[0])

    error_queue.close
    th.join
    exit @exit_status
  end

  private def command_config
    n = args[0].to_i
    puts File.read(configs[n])
  end

  private def run_for(repo)
    Runner.new(repo, configs: configs, error_queue: error_queue, debug: debug).run
  end

  private def configs
    @configs ||= ConfigGenerator.generate_configs
  end

  private def watch_error_queue
    Thread.new do
      while err = error_queue.pop
        puts err.message + "\n"
        @exit_status = EXIT_STATUS_ERR
      end
    end
  end

  private def subcommand
    @argv[0]
  end

  private def args
    @argv[1..]
  end

  private def usage!
    puts <<~USAGE
      Usage:
        ruby main.rb check OWNER/REPO         # Run the test
        ruby main.rb check GIT_CLONEABLE_PATH # Run the test
        ruby main.rb config NUMBER            # Generate configuration
        ruby main.rb help                     # Display this message
    USAGE
    exit EXIT_STATUS_ERR
  end
end
