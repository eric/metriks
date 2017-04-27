require 'test_helper'
require 'thread_error_handling_tests'

require 'metriks/reporter/riemann'

class RiemannReporterTest < Test::Unit::TestCase
  include ThreadErrorHandlingTests

  def build_reporter(options={})
    Metriks::Reporter::Riemann.new({
      :host => "foo",
      :port => 1234,
      :registry => @registry,
      :default_event => {:host => "h"}
    }.merge(options))
  end

  def setup
    @registry = Metriks::Registry.new
    @reporter = build_reporter
  end

  def teardown
    @reporter.stop
    @registry.stop
  end

  def test_init
    assert_equal @reporter.client.host, "foo"
    assert_equal @reporter.client.port, 1234
  end

  def test_write
    @registry.meter('meter.testing').mark
    @registry.counter('counter.testing').increment
    @registry.timer('timer.testing').update(1.5)
    @registry.histogram('histogram.testing').update(1.5)
    @registry.utilization_timer('utilization_timer.testing').update(1.5)
    @registry.gauge('gauge.testing') { 123 }

    @reporter.client.expects(:<<).at_least_once
    @reporter.client.expects(:<<).with(
      :host => "h",
      :service => "meter.testing count",
      :metric => 1,
      :tags => ["meter"],
      :ttl => 90
    )
    @reporter.client.expects(:<<).with(
      :host => "h",
      :service => "counter.testing count",
      :metric => 1,
      :tags => ["counter"],
      :ttl => 90
    )
    @reporter.client.expects(:<<).with(
      :host => "h",
      :service => "timer.testing max",
      :metric => 1.5,
      :tags => ["timer"],
      :ttl => 90
    )
    @reporter.client.expects(:<<).with(
      :host => "h",
      :service => "histogram.testing max",
      :metric => 1.5,
      :tags => ["histogram"],
      :ttl => 90
    )
    @reporter.client.expects(:<<).with(
      :host => "h",
      :service => "utilization_timer.testing mean",
      :metric => 1.5,
      :tags => ["utilization_timer"],
      :ttl => 90
    )

    @reporter.client.expects(:<<).with(
      :host => "h",
      :service => "gauge.testing value",
      :metric => 123,
      :tags => ["gauge"],
      :ttl => 90
    )

    @reporter.write
  end

def test_custom_percentiles_for_timers
    @reporter = build_reporter(:percentiles => :p999)
    @registry.timer('timer.testing').update(1.5)
    mock_snapshot = @registry.timer('timer.testing').snapshot
    mock_snapshot.expects(:get_999th_percentile)
    @registry.timer('timer.testing').stubs(:snapshot).returns(mock_snapshot)

    @reporter.stubs(:client).returns([])
    @reporter.write
  end

  def test_custom_percentiles_for_utilization_timers
    @reporter = build_reporter(:percentiles => :p999)
    @registry.utilization_timer('utilization_timer.testing').update(1.5)
    mock_snapshot = @registry.utilization_timer('utilization_timer.testing').snapshot
    mock_snapshot.expects(:get_999th_percentile)
    @registry.utilization_timer('utilization_timer.testing').stubs(:snapshot).returns(mock_snapshot)

    @reporter.stubs(:client).returns([])
    @reporter.write
  end

  def test_custom_percentiles_for_histograms
    @reporter = build_reporter(:percentiles => :p999)
    @registry.histogram('histogram.testing').update(1.5)
    mock_snapshot = @registry.histogram('histogram.testing').snapshot
    mock_snapshot.expects(:get_999th_percentile)
    @registry.histogram('histogram.testing').stubs(:snapshot).returns(mock_snapshot)

    @reporter.stubs(:client).returns([])
    @reporter.write
  end

  def test_default_percentile
    assert_equal [:get_95th_percentile], @reporter.percentile_methods
  end
end
