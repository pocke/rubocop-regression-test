require_relative 'lib/runner'

def main(argv)
  raise "unexpected arguments" if argv.size != 1

  configs = (ENV['CONFIGS'] && ENV['CONFIGS'].split(' ')) || [:force_default_config]

  runner = Runner.new(argv.first, configs: configs)
  runner.run
end

main(ARGV)
