require 'tmpdir'
require 'open3'
require 'fileutils'

class Runner
  LOG_DIRECTORY = '/tmp/rubocop-regression-test/log/'
  FileUtils.mkdir_p(LOG_DIRECTORY) unless File.directory?(LOG_DIRECTORY)

  class ExecRuboCopError < StandardError
    def initialize(message:, command:, repo:, sha:, log_path:)
      @message = message
      @command = command
      @repo = repo
      @sha = sha
      @log_path = log_path
    end

    def message
      <<~END
        #{@message}
        See #{@log_path}
        Please try executing the following command in #{@repo}, commit #{@sha}
        #{@command.join(' ')}
      END
    end
  end

  def initialize(repo, configs:, error_queue:, debug:)
    repo = "git@github.com:#{repo}.git" if repo.match(%r!\A[^/]+/[^/]+\z!)
    @repo = repo
    @configs = configs
    @error_queue = error_queue
    @debug = debug
  end

  def run
    Dir.mktmpdir('rubocop-regression-test-') do |dir|
      @working_dir = dir

      fetch
      configs.each do |config, cop_names|
        run_rubocop_with_config(config: config, cop_names: cop_names)
      end
    end
  end

  private

  attr_reader :repo, :configs, :working_dir, :sha, :error_queue, :debug

  def fetch
    system! 'git', 'clone', '--depth=1', repo, working_dir
    print "HEAD: " if debug
    sha, status = Open3.capture2('git', 'rev-parse', 'HEAD', chdir: working_dir)
    @sha = sha.chomp
    raise "Unexpected status #{status.exitstatus}" unless status.success?
    puts @sha if debug
  end

  def system!(*cmd)
    puts "$ " + cmd.join(' ') if debug
    unless debug
      if cmd.last.is_a?(Hash)
        opt = cmd.last.merge({out: '/dev/null', err: '/dev/null'})
        cmd = [*cmd[0..-2], opt]
      else
        cmd = [*cmd, {out: '/dev/null', err: '/dev/null'}]
      end
    end
    system(*cmd)
    raise "Unexpected status: #{$?.exitstatus}" unless $?.success?
  end

  def run_rubocop_with_config(config:, cop_names:)
    opt =
      case config
      when :force_default_config
        ['--force-default-config']
      else
        ['--config', config]
      end
    if cop_names
      opt << '--only'
      opt << cop_names.join(',')
    end

    exec_rubocop(*opt) # With default formatter
    exec_rubocop '--auto-correct', *opt
    system! 'git', 'reset', '--hard', chdir: working_dir
  end

  def exec_rubocop(*opts)
    cmd = ['rubocop', '--debug'] + opts
    cmd << '--parallel' unless opts.include?('--auto-correct')
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
    push_error(message: "An error occrred! see the log.", command: cmd, stdout: out)if out =~ /An error occurred while/
  end

  def push_error(message:, command:, stdout:)
    log_path = File.join(LOG_DIRECTORY, Time.now.to_f.to_s)
    File.write(log_path, "$ #{command.join(' ')}\n" + stdout)
    err = ExecRuboCopError.new(message: message, command: command, repo: repo, sha: sha, log_path: log_path)
    error_queue.push err
  end
end
