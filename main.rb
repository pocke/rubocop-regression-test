require 'optparse'
require_relative 'lib/runner'

def main(argv)
  opt = OptionParser.new
  params = {}
  opt.on('--config str') {|str| params[:config] = str}
  args = opt.parse(argv)
  raise "unexpected arguments" if args.size != 1

  runner = Runner.new(args.first, config: params[:config])
  runner.run
end

main(ARGV)
