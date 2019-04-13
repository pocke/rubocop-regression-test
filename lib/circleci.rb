class CircleCI
  def self.start
    return unless ENV['CIRCLECI']

    Thread.new do
      loop do
        sleep 9 * 60
        print '.'
      end
    end
  end
end
