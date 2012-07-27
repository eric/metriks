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

    @reporter.expects(:submit)

    @reporter.write
  end

  def assert_generated(count, options)
    @registry.timer('timer.testing').update(1.5)

    metrics = build_reporter(options).prepare_metrics
    assert_equal(count, metrics.length)
  end

  def test_no_filters
    assert_generated(11, {})
  end

  def test_only
    assert_generated(2, {:only => [:count, :median]})
  end

  def test_except
    assert_generated(9, {:except => [:count, :median]})
  end
end
