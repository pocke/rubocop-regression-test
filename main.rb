require_relative 'lib/runner'
require_relative 'lib/executor'
require_relative 'lib/config_generator'
require_relative 'lib/cli'
require_relative 'lib/circleci'
require_relative 'lib/execute_id'

CLI.start(ARGV)
