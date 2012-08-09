require 'test_helper'
require 'thread_error_handling_tests'

require 'logger'
require 'metriks/reporter/logger'

class LoggerReporterTest < Test::Unit::TestCase
  include ThreadErrorHandlingTests

  def build_reporter(options={})
    Metriks::Reporter::Logger.new({ :registry => @registry, :logger => @logger }.merge(options))
  end

  def setup
    @stringio = StringIO.new
    @logger   = ::Logger.new(@stringio)
    @registry = Metriks::Registry.new

    @reporter = build_reporter

    @registry.meter('meter.testing').mark
    @registry.counter('counter.testing').increment
    @registry.timer('timer.testing').update(1.5)
    @registry.histogram('histogram.testing').update(1.5)
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

  def test_write_regression
    Time.stubs(:now).returns(Time.new(2012, 4, 1))
    Metriks::Meter.any_instance.stubs(:mean_rate).returns('42')
    Metriks::UtilizationTimer.any_instance.stubs(:mean_utilization).returns('42')

    expected = "INFO -- : metriks: time=1333252800 name=meter.testing type=meter count=1 one_minute_rate=0.0 five_minute_rate=0.0 fifteen_minute_rate=0.0 mean_rate=42
INFO -- : metriks: time=1333252800 name=counter.testing type=counter count=1
INFO -- : metriks: time=1333252800 name=timer.testing type=timer count=1 one_minute_rate=0.0 five_minute_rate=0.0 fifteen_minute_rate=0.0 mean_rate=42 min=1.5 max=1.5 mean=1.5 stddev=0.0 median=1.5 95th_percentile=1.5
INFO -- : metriks: time=1333252800 name=histogram.testing type=histogram count=1 min=1.5 max=1.5 mean=1.5 stddev=0.0 median=1.5 95th_percentile=1.5
INFO -- : metriks: time=1333252800 name=utilization_timer.testing type=utilization_timer count=1 one_minute_rate=0.0 five_minute_rate=0.0 fifteen_minute_rate=0.0 mean_rate=42 min=1.5 max=1.5 mean=1.5 stddev=0.0 one_minute_utilization=0.0 five_minute_utilization=0.0 fifteen_minute_utilization=0.0 mean_utilization=42 median=1.5 95th_percentile=1.5
"

    @reporter.write
    output = @stringio.string.gsub!(/^I,.* INFO/, 'INFO')
    assert_equal expected, output
  end

  def test_flush
    @reporter.flush

    assert_match /time=\d/, @stringio.string
    assert_match /median=\d/, @stringio.string
  end
end
