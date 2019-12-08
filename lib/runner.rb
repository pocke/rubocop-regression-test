require 'tmpdir'
require 'open3'
require 'fileutils'
require 'etc'

class Runner
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

  class ErrorNotifier
    def initialize(error_queue:, repo:, sha:)
      @error_queue = error_queue
      @repo = repo
      @sha = sha
    end

    def notify(message:, command:, log_path:)
      err = ExecRuboCopError.new(message: message, command: command, repo: @repo, sha: @sha, log_path: log_path)
      @error_queue.push err
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
      @source_dir = dir
      fetch

      notifier = ErrorNotifier.new(error_queue: error_queue, repo: repo, sha: sha)

      executors_queue = Thread::Queue.new

      configs.each do |config|
        executors_queue << Executor.new(config: config, source_dir: dir, auto_correct: true, debug: debug, error_notifier: notifier)
        executors_queue << Executor.new(config: config, source_dir: dir, auto_correct: false, debug: debug, error_notifier: notifier)
      end
      executors_queue.close

      threads = thread_count.times.map do
        Thread.new do
          while e = executors_queue.pop
            e.execute
          end
        end
      end
      threads.each(&:join)
    end
  end

  attr_reader :repo, :configs, :source_dir, :sha, :error_queue, :debug
  private :repo, :configs, :source_dir, :sha, :error_queue, :debug

  private def fetch
    system! 'git', 'clone', '--depth=1', repo, source_dir
    print "HEAD: " if debug
    sha, status = Open3.capture2('git', 'rev-parse', 'HEAD', chdir: source_dir)
    @sha = sha.chomp
    raise "Unexpected status #{status.exitstatus}" unless status.success?
    puts @sha if debug
  end

  private def system!(*cmd)
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

  private def thread_count
    if ENV['CIRCLECI']
      # CircleCI container has two cores, but Ruby can see 32 cores.
      # So we use 2 + 1 cores.
      3
    else
      Etc.nprocessors
    end
  end
end
