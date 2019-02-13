require 'tmpdir'
require 'open3'

class Runner
  def initialize(repo, config:)
    repo = "git@github.com:#{repo}.git" if repo.match(%r!\A[^/]+/[^/]+\z!)
    @repo = repo
    @config = config
  end

  def run
    Dir.mktmpdir('rubocop-regression-test-') do |dir|
      @working_dir = dir

      fetch
      run_rubocop
    end
  end

  private

  attr_reader :repo, :config, :working_dir

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

  def run_rubocop
    cmd = ['rubocop', '--debug']
    puts "$ " + cmd.join(' ')
    out, status = Open3.capture2e(*cmd, chdir: working_dir)
    print out
    raise "Unexpected status: #{status.exitstatus}" unless [0, 1].include?(status.exitstatus)
    raise "An error occrred! see the log." if out =~ /An error occurred while/
  end
end
