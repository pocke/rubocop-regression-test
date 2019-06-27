require 'tmpdir'

class Executor
  LOG_DIRECTORY = '/tmp/rubocop-regression-test/log/'
  FileUtils.mkdir_p(LOG_DIRECTORY) unless File.directory?(LOG_DIRECTORY)

  def initialize(config:, cop_names:, source_dir:, auto_correct:, debug:, error_notifier:)
    @config = config
    @cop_names = cop_names
    @source_dir = source_dir
    @auto_correct = auto_correct
    @working_dir = nil
    @debug = debug
    @error_notifier = error_notifier
  end

  def execute
    with_working_dir do
      run_rubocop_with_config
    end
  end

  attr_reader :config, :cop_names, :source_dir, :auto_correct, :working_dir, :debug, :error_notifier
  private :config, :cop_names, :source_dir, :auto_correct, :working_dir, :debug, :error_notifier

  private def with_working_dir(&block)
    if auto_correct
      Dir.mktmpdir('rubocop-regression-test-') do |dir|
        FileUtils.copy_entry(source_dir, dir)
        @working_dir = dir
        block.call
      end
    else
      @working_dir = source_dir
      block.call(source_dir)
    end
  end

  private def run_rubocop_with_config
    opt = ['--config', config]

    if cop_names
      opt << '--only'
      opt << cop_names.join(',')
    end

    if auto_correct
      opt.unshift '--auto-correct'
    end

    exec_rubocop(*opt)
  end

  private def exec_rubocop(*opts)
    cmd = ['rubocop', '--debug'] + opts
    puts "$ " + cmd.join(' ') if debug
    # TODO: Replace capture2e with some pipe method,
    #       because capture2e stores output as a string.
    #       It may uses too much memory.
    out, status = Open3.capture2e(*cmd, chdir: working_dir)
    unless [0, 1].include?(status.exitstatus)
      # Infinite loop is noisy, so ignore it.
      # If you challenge to remove infinite loop, let's remove this condition!
      unless out.include?('Infinite loop detected in')
        push_error(message: "Unexpected status: #{status.exitstatus}", command: cmd, stdout: out)
      end
    end
    push_error(message: "An error occrred! see the log.", command: cmd, stdout: out)if out =~ /^An error occurred while/
  end

  private def push_error(message:, command:, stdout:)
    log_path = File.join(LOG_DIRECTORY, Time.now.to_f.to_s)
    File.write(log_path, "$ #{command.join(' ')}\n" + stdout)
    error_notifier.notify(message: message, command: command, log_path: log_path)
  end
end
