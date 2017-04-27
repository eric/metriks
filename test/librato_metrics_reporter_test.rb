require 'test_helper'
require 'thread_error_handling_tests'

require 'metriks/reporter/librato_metrics'

class LibratoMetricsReporterTest < Test::Unit::TestCase
  include ThreadErrorHandlingTests

  def build_reporter(options={})
    Metriks::Reporter::LibratoMetrics.new('user', 'password', { :registry => @registry }.merge(options))
  end

  def setup
    @registry = Metriks::Registry.new
    @reporter = build_reporter
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
    @registry.gauge('gauge.testing') { 123 }

    @reporter.expects(:submit)

    @reporter.write
  end

  def test_custom_percentiles_for_timers
    @reporter = build_reporter(:percentiles => :p999)
    @registry.timer('timer.testing').update(1.5)
    mock_snapshot = @registry.timer('timer.testing').snapshot
    mock_snapshot.expects(:get_999th_percentile)
    @registry.timer('timer.testing').stubs(:snapshot).returns(mock_snapshot)

    @reporter.stubs(:submit)
    @reporter.write
  end

  def test_custom_percentiles_for_utilization_timers
    @reporter = build_reporter(:percentiles => :p999)
    @registry.utilization_timer('utilization_timer.testing').update(1.5)
    mock_snapshot = @registry.utilization_timer('utilization_timer.testing').snapshot
    mock_snapshot.expects(:get_999th_percentile)
    @registry.utilization_timer('utilization_timer.testing').stubs(:snapshot).returns(mock_snapshot)

    @reporter.stubs(:submit)
    @reporter.write
  end

  def test_custom_percentiles_for_histograms
    @reporter = build_reporter(:percentiles => :p999)
    @registry.histogram('histogram.testing').update(1.5)
    mock_snapshot = @registry.histogram('histogram.testing').snapshot
    mock_snapshot.expects(:get_999th_percentile)
    @registry.histogram('histogram.testing').stubs(:snapshot).returns(mock_snapshot)

    @reporter.stubs(:submit)
    @reporter.write
  end

  def test_default_percentile
    assert_equal [:get_95th_percentile], @reporter.percentile_methods
  end
end
