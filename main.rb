require_relative 'lib/runner'

def main(argv)
  if argv.empty?
    run_all_repos
  else
    run_one_repo(argv)
  end
end

TARGET_REPOSITORIES = %w[
  tric/trick2013
  tric/trick2015
  tric/trick2018
  ruby/ruby
  ruby/spec
  rails/rails
  gitlabhq/gitlabhq
  discourse/discourse
]

def run_one_repo(argv)
  raise "unexpected arguments" if argv.size != 1

  configs = (ENV['CONFIGS'] && ENV['CONFIGS'].split(' ')) || [:force_default_config]

  runner = Runner.new(argv.first, configs: configs)
  runner.run
end

def run_all_repos
  TARGET_REPOSITORIES.each do |repo|
    Runner.new(repo, configs: [:force_default_config]).run
  end
end

main(ARGV)
