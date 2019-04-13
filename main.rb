require_relative 'lib/runner'
require_relative 'lib/config_generator'
require_relative 'lib/cli'
require_relative 'lib/circleci'

CLI.start(ARGV)
