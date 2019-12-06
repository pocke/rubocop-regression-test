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
      check
    when 'generate_config'
      generate_config
    when 'help'
      usage!
    end
  end

  attr_reader :argv, :error_queue, :debug
  private :argv, :error_queue, :debug

  private def check
    th = watch_error_queue
    CircleCI.start
    run_for(argv[1])

    error_queue.close
    th.join
    exit @exit_status
  end

  private def generate_config
    raise 'WIP'
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

  private def usage!
    puts <<~USAGE
      Usage:
        ruby main.rb check OWNER/REPO       # Run the test
        ruby main.rb generate_config NUMBER # Generate configuration
        ruby main.rb help                   # Display this message
    USAGE
    exit EXIT_STATUS_ERR
  end
end
