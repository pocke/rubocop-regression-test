require_relative 'lib/runner'
require_relative 'lib/config_generator'

def main(argv)
  if argv.empty?
    run_all_repos
  else
    run_one_repo(argv)
  end
end

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

def run_one_repo(argv)
  raise "unexpected arguments" if argv.size != 1

  configs = (ENV['CONFIGS'] && ENV['CONFIGS'].split(' ')) || [:force_default_config]

  runner = Runner.new(argv.first, configs: configs)
  runner.run
end

def run_all_repos
  configs = ConfigGenerator.generate_configs + [:force_default_config]
  TARGET_REPOSITORIES.each do |repo|
    Runner.new(repo, configs: configs).run
  end
end

main(ARGV)
