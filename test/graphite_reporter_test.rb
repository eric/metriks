require 'test_helper'
require 'thread_error_handling_tests'

require 'metriks/reporter/graphite'

class GraphiteReporterTest < Test::Unit::TestCase
  include ThreadErrorHandlingTests

  def build_reporter(options={})
    Metriks::Reporter::Graphite.new('localhost', 3333, { :registry => @registry }.merge(options))
  end

  def setup
    @registry = Metriks::Registry.new
    @reporter = build_reporter
    @stringio = StringIO.new

    @reporter.stubs(:socket).returns(@stringio)
  end

  def teardown
    @reporter.stop
    @registry.stop
  end

  def test_write
    @registry.meter('meter.testing').mark
    @registry.counter('counter.testing').increment
    @registry.timer('timer.testing').update(1.5)
    @registry.histogram('histogram.testing').update(1.5)
    @registry.utilization_timer('utilization_timer.testing').update(1.5)

    @reporter.write

    assert_match /timer.testing.median \d/, @stringio.string
  end

  def test_write_omg
    @registry.meter('meter.testing').mark
    @registry.counter('counter.testing').increment
    @registry.timer('timer.testing').update(1.5)
    @registry.histogram('histogram.testing').update(1.5)
    @registry.utilization_timer('utilization_timer.testing').update(1.5)

    Time.stubs(:now).returns(Time.new(2012, 4, 1))
    Metriks::TimeTracker.any_instance.stubs(:now_floored).returns('42')
    Metriks::Meter.any_instance.stubs(:mean_rate).returns('42')
    Metriks::UtilizationTimer.any_instance.stubs(:mean_utilization).returns('42')

    @reporter.write

    expected = "meter.testing.count 1 1333252800
meter.testing.one_minute_rate 0.0 1333252800
meter.testing.five_minute_rate 0.0 1333252800
meter.testing.fifteen_minute_rate 0.0 1333252800
meter.testing.mean_rate 42 1333252800
counter.testing.count 1 1333252800
timer.testing.count 1 1333252800
timer.testing.one_minute_rate 0.0 1333252800
timer.testing.five_minute_rate 0.0 1333252800
timer.testing.fifteen_minute_rate 0.0 1333252800
timer.testing.mean_rate 42 1333252800
timer.testing.min 1.5 1333252800
timer.testing.max 1.5 1333252800
timer.testing.mean 1.5 1333252800
timer.testing.stddev 0.0 1333252800
timer.testing.median 1.5 1333252800
timer.testing.95th_percentile 1.5 1333252800
histogram.testing.count 1 1333252800
histogram.testing.min 1.5 1333252800
histogram.testing.max 1.5 1333252800
histogram.testing.mean 1.5 1333252800
histogram.testing.stddev 0.0 1333252800
histogram.testing.median 1.5 1333252800
histogram.testing.95th_percentile 1.5 1333252800
utilization_timer.testing.count 1 1333252800
utilization_timer.testing.one_minute_rate 0.0 1333252800
utilization_timer.testing.five_minute_rate 0.0 1333252800
utilization_timer.testing.fifteen_minute_rate 0.0 1333252800
utilization_timer.testing.mean_rate 42 1333252800
utilization_timer.testing.min 1.5 1333252800
utilization_timer.testing.max 1.5 1333252800
utilization_timer.testing.mean 1.5 1333252800
utilization_timer.testing.stddev 0.0 1333252800
utilization_timer.testing.one_minute_utilization 0.0 1333252800
utilization_timer.testing.five_minute_utilization 0.0 1333252800
utilization_timer.testing.fifteen_minute_utilization 0.0 1333252800
utilization_timer.testing.mean_utilization 42 1333252800
utilization_timer.testing.median 1.5 1333252800
utilization_timer.testing.95th_percentile 1.5 1333252800
"
    assert_equal expected, @stringio.string
  end
end
