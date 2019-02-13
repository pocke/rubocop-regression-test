require 'tmpdir'
require 'open3'
require 'rubocop'

class Runner
  FORMATTERS = RuboCop::Formatter::FormatterSet::BUILTIN_FORMATTERS_FOR_KEYS.keys

  def initialize(repo, configs:)
    repo = "git@github.com:#{repo}.git" if repo.match(%r!\A[^/]+/[^/]+\z!)
    @repo = repo
    @configs = configs
  end

  def run
    Dir.mktmpdir('rubocop-regression-test-') do |dir|
      @working_dir = dir

      fetch
      configs.each do |config|
        run_rubocop_with_config(config: config)
      end
    end
  end

  private

  attr_reader :repo, :configs, :working_dir

  def fetch
    system! 'git', 'clone', '--depth=1', repo, working_dir
    print "HEAD: "
    system! 'git', 'rev-parse', 'HEAD', chdir: working_dir
  end

  def system!(*cmd)
    puts "$ " + cmd.join(' ')
    system(*cmd)
    raise "Unexpected status: #{$?.exitstatus}" unless $?.success?
  end

  def run_rubocop_with_config(config:)
    config_opt =
      case config
      when :force_default_config
        ['--force-default-config']
      else
        ['--config', config]
      end

    exec_rubocop(*config_opt) # With default formatter
    FORMATTERS.each do |f|
      # Changing formatter uses the cache, so it does not take a long time.
      exec_rubocop '-f', f, *config_opt
    end
    exec_rubocop '--auto-correct', *config_opt
  end

  def exec_rubocop(*opts)
    cmd = ['rubocop', '--debug', '--rails'] + opts
    cmd << '--parallel' unless opts.include?('--auto-correct')
    puts "$ " + cmd.join(' ')
    # TODO: Replace capture2e with some pipe method,
    #       because capture2e stores output as a string.
    #       It may uses too much memory.
    out, status = Open3.capture2e(*cmd, chdir: working_dir)
    print out
    raise "Unexpected status: #{status.exitstatus}" unless [0, 1].include?(status.exitstatus)
    raise "An error occrred! see the log." if out =~ /An error occurred while/
  end
end
