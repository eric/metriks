require 'test_helper'

require 'logger'
require 'metriks/reporter/logger'

class LoggerReporterTest < Test::Unit::TestCase
  def setup
    @stringio = StringIO.new
    @logger   = ::Logger.new(@stringio)
    @registry = Metriks::Registry.new

    @reporter = Metriks::Reporter::Logger.new(:registry => @registry, :logger => @logger)

    @registry.meter('meter.testing').mark
    @registry.counter('counter.testing').increment
    @registry.timer('timer.testing').update(1.5)
    @registry.utilization_timer('utilization_timer.testing').update(1.5)
  end

  def teardown
    @reporter.stop
    @registry.stop
  end

  def test_write
    @reporter.write

    assert_match /time=\d/, @stringio.string
    assert_match /median=\d/, @stringio.string
  end

  def test_flush
    @reporter.flush

    assert_match /time=\d/, @stringio.string
    assert_match /median=\d/, @stringio.string
  end
end