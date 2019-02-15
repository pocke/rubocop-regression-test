class CLI
  TARGET_REPOSITORIES = [
    # tric has many tricky code
    'tric/trick2013',
    'tric/trick2015',
    'tric/trick2018',
    # ruby/spec has many edge cases
    'ruby/spec',
    # They have really large code base.
    'ruby/ruby',
    'rails/rails',
    'gitlabhq/gitlabhq',
    'discourse/discourse',
  ]

  EXIT_STATUS_SUCCSESS = 0
  EXIT_STATUS_ERR = 2

  def self.start(argv)
    new(argv).start
  end

  def initialize(argv)
    @argv = argv
    @error_queue = Thread::Queue.new
    @exit_status = EXIT_STATUS_SUCCSESS
    @debug = ENV['DEBUG']
  end

  def start
    th = watch_error_queue

    if argv.empty?
      run_all_repos
    else
      run_for(argv.first)
    end

    error_queue.close
    th.join
    exit @exit_status
  end

  private

  attr_reader :argv, :error_queue, :debug

  def run_for(repo)
    Runner.new(repo, configs: configs, error_queue: error_queue, debug: debug).run
  end

  def configs
    @configs ||= ConfigGenerator.generate_configs + [[:force_default_config, nil]]
  end

  def run_all_repos
    TARGET_REPOSITORIES.each do |repo|
      run_for repo
    end
  end

  def watch_error_queue
    Thread.new do
      while err = error_queue.pop
        puts err.message + "\n"
        @exit_status = EXIT_STATUS_ERR
      end
    end
  end
end
