require 'test/unit'
require 'mocha'
require 'metriks/reporter/librato_metrics'

Thread.abort_on_exception = true

class LibratoMetricsReporterIsolatedTest < Test::Unit::TestCase
  def stub_iterator(*args)
    metric = stub
    metric.expects(:each).multiple_yields(*args)
    metric
  end

  def simple_registry
    stub_iterator([ 'registry', stub_iterator([ 'count', 1 ])])
  end

  ### Options

  def test_prefix_metric_names
    reporter = Metriks::Reporter::LibratoMetrics.
                 new('user', 'password', :prefix   => 'prefix',
                                         :registry => simple_registry)
    reporter.expects(:submit).
      with(has_entry('counters[0][name]' => 'prefix.registry.count'))
    reporter.write
    assert_equal 'prefix', reporter.prefix
  end

  def test_default_prefix_is_blank
    reporter = Metriks::Reporter::LibratoMetrics.
                 new('user', 'password', :registry => simple_registry)
    reporter.expects(:submit).
      with(has_entry('counters[0][name]' => 'registry.count'))
    reporter.write
    assert_nil reporter.prefix
  end

  def test_specify_source
    reporter = Metriks::Reporter::LibratoMetrics.
                 new('user', 'password', :source   => 'source',
                                         :registry => simple_registry)
    reporter.expects(:submit).
      with(has_entry('counters[0][source]' => 'source'))
    reporter.write
    assert_equal 'source', reporter.source
  end

  def test_default_source_is_omitted
    reporter = Metriks::Reporter::LibratoMetrics.
                 new('user', 'password', :registry => simple_registry)
    reporter.expects(:submit).with(Not(has_key('counters[0][source]')))
    reporter.write
    assert_nil reporter.source
  end

  def test_specify_registry
    registry = stub
    registry.expects(:each)
    reporter = Metriks::Reporter::LibratoMetrics.
                 new('user', 'password', :registry => registry)
    reporter.write
  end

  def test_uses_default_registry
    registry = stub
    registry.expects(:each)
    Metriks::Registry.expects(:default).returns(registry)
    Metriks::Reporter::LibratoMetrics.new('user', 'password').write
  end

  # TODO: These tests don't really test the interval. Tie them in with #start
  # tests when written.
  def test_specify_interval
    Metriks::TimeTracker.expects(:new).with(42)
    Metriks::Reporter::LibratoMetrics.new('user', 'password', :interval => 42)
  end

  def test_default_interval_one_minute
    Metriks::TimeTracker.expects(:new).with(60)
    Metriks::Reporter::LibratoMetrics.new('user', 'password')
  end

  def test_report_only_matching_metric
    registry = stub_iterator([ 'registry', stub_iterator([ 'one',   1.1 ])],
                             [ 'registry', stub_iterator([ 'two',   2.2 ],
                                                         [ 'three', 3.3 ]) ])
    reporter = Metriks::Reporter::LibratoMetrics.
                 new('user', 'password', :registry => registry,
                                         :only     => ['registry.one'])
    reporter.expects(:submit).with do |data|
      data.has_key?('gauges[0][name]')    &&
        !data.has_key?('gauges[1][name]') &&
        !data.has_key?('gauges[2][name]') &&
        data['gauges[0][name]'] == 'registry.one'
    end
    reporter.write
  end

  def test_report_only_several_matching_metric
    registry = stub_iterator([ 'registry', stub_iterator([ 'one',   1.1 ])],
                             [ 'registry', stub_iterator([ 'two',   2.2 ],
                                                         [ 'three', 3.3 ]) ])
    reporter = Metriks::Reporter::LibratoMetrics.
                 new('user', 'password', :registry => registry,
                                         :only     => %w( registry.one
                                                          registry.three ))
    reporter.expects(:submit).with do |data|
      data.has_key?('gauges[0][name]')    &&
        data.has_key?('gauges[1][name]')  &&
        !data.has_key?('gauges[2][name]') &&
        data['gauges[0][name]'] == 'registry.one' &&
        data['gauges[1][name]'] == 'registry.three'
    end
    reporter.write
  end

  def test_only_matches_using_threequals_operator
    registry = stub_iterator([ 'registry', stub_iterator([ 'one',   1.1 ])],
                             [ 'registry', stub_iterator([ 'two',   2.2 ],
                                                         [ 'three', 3.3 ]) ])
    matcher = stub
    matcher.expects(:===).with('registry.one')
    matcher.expects(:===).with('registry.two')
    matcher.expects(:===).with('registry.three')
    reporter = Metriks::Reporter::LibratoMetrics.
                 new('user', 'password', :registry => registry,
                                         :only     => [matcher])
    reporter.write
  end

  def test_report_except_matching_metric
    registry = stub_iterator([ 'registry', stub_iterator([ 'one',   1.1 ])],
                             [ 'registry', stub_iterator([ 'two',   2.2 ],
                                                         [ 'three', 3.3 ]) ])
    reporter = Metriks::Reporter::LibratoMetrics.
                 new('user', 'password', :registry => registry,
                                         :except   => ['registry.one'])
    reporter.expects(:submit).with do |data|
      data.has_key?('gauges[0][name]')    &&
        data.has_key?('gauges[1][name]')  &&
        !data.has_key?('gauges[2][name]') &&
        data['gauges[0][name]'] == 'registry.two' &&
        data['gauges[1][name]'] == 'registry.three'
    end
    reporter.write
  end

  def test_report_except_several_matching_metric
    registry = stub_iterator([ 'registry', stub_iterator([ 'one',   1.1 ])],
                             [ 'registry', stub_iterator([ 'two',   2.2 ],
                                                         [ 'three', 3.3 ]) ])
    reporter = Metriks::Reporter::LibratoMetrics.
                 new('user', 'password', :registry => registry,
                                         :except   => %w( registry.one
                                                          registry.three ))
    reporter.expects(:submit).with do |data|
      data.has_key?('gauges[0][name]')    &&
        !data.has_key?('gauges[1][name]') &&
        !data.has_key?('gauges[2][name]') &&
        data['gauges[0][name]'] == 'registry.two'
    end
    reporter.write
  end

  def test_except_matches_using_threequals_operator
    registry = stub_iterator([ 'registry', stub_iterator([ 'one',   1.1 ])],
                             [ 'registry', stub_iterator([ 'two',   2.2 ],
                                                         [ 'three', 3.3 ]) ])
    matcher = stub
    matcher.expects(:===).with('registry.one')
    matcher.expects(:===).with('registry.two')
    matcher.expects(:===).with('registry.three')
    reporter = Metriks::Reporter::LibratoMetrics.
                 new('user', 'password', :registry => registry,
                                         :except   => [matcher])
    reporter.stubs(:submit)
    reporter.write
  end

  def test_specify_error_handler
    Metriks::TimeTracker.any_instance.stubs(:sleep)
    handler = stub
    handler.expects(:[]).with(kind_of(RuntimeError)).at_least_once
    reporter = Metriks::Reporter::LibratoMetrics.new('user', 'password',
                                                     :on_error => handler)
    def reporter.write() raise('write') end

    reporter.start
    sleep 0.01
    reporter.stop
  end

  def test_swallows_errors_raised_in_error_handler
    Metriks::TimeTracker.any_instance.stubs(:sleep)
    handler = stub
    handler.expects(:[]).raises(RuntimeError).at_least_once
    reporter = Metriks::Reporter::LibratoMetrics.new('user', 'password',
                                                     :on_error => handler)
    def reporter.write() raise('write') end

    reporter.start
    sleep 0.01
    reporter.stop
  end

  def test_default_error_handler_swallows_errors
    Metriks::TimeTracker.any_instance.stubs(:sleep)
    reporter = Metriks::Reporter::LibratoMetrics.new('user', 'password')
    def reporter.write() raise('write') end

    reporter.start
    sleep 0.01
    reporter.stop
  end

  ### Public Methods

  def test_stop
    Metriks::TimeTracker.any_instance.stubs(:sleep)
    reporter = Metriks::Reporter::LibratoMetrics.new('user', 'password')
    reporter.start
    reporter.stop
    reporter.expects(:write).never
    sleep 0.01
  end

  def test_stop_unstarted_reporter
    reporter = Metriks::Reporter::LibratoMetrics.new('user', 'password')
    assert_nothing_raised { reporter.stop }
  end

  def test_write
    Metriks::TimeTracker.any_instance.stubs(:now_floored).returns(42)
    registry = stub_iterator([ 'registry', stub_iterator([ 'one', 1.1 ])])
    reporter = Metriks::Reporter::LibratoMetrics.
                 new('user', 'password', :registry => registry)
    expected = { 'gauges[0][type]'         => 'gauge',
                 'gauges[0][name]'         => 'registry.one',
                 'gauges[0][measure_time]' => '42',
                 'gauges[0][value]'        => '1.1' }
    reporter.expects(:submit).with(expected)
    reporter.write
  end

  def test_write_several_metrics
    registry = stub_iterator([ 'registry', stub_iterator([ 'one',   1.1 ])],
                             [ 'registry', stub_iterator([ 'two',   2.2 ],
                                                         [ 'three', 3.3 ]) ])
    reporter = Metriks::Reporter::LibratoMetrics.new('user', 'password',
                                                     :registry => registry)
    expected = { 'gauges[0][name]'  => 'registry.one',
                 'gauges[0][value]' => '1.1',
                 'gauges[1][name]'  => 'registry.two',
                 'gauges[1][value]' => '2.2',
                 'gauges[2][name]'  => 'registry.three',
                 'gauges[2][value]' => '3.3' }
    reporter.expects(:submit).with(has_entries(expected))
    reporter.write
  end

  def test_write_counters
    registry = stub_iterator([ 'registry', stub_iterator([ 'count', 1 ])])
    reporter = Metriks::Reporter::LibratoMetrics.new('user', 'password',
                                                     :registry => registry)
    expected = { 'counters[0][type]' => 'counter' }
    reporter.expects(:submit).with(has_entries(expected))
    reporter.write
  end

  def test_write_records_times_once_per_metric
    Metriks::TimeTracker.any_instance.stubs(:now_floored).returns(42).twice
    registry = stub_iterator([ 'registry', stub_iterator([ 'one',   1.1 ])],
                             [ 'registry', stub_iterator([ 'two',   2.2 ],
                                                         [ 'three', 3.3 ]) ])
    reporter = Metriks::Reporter::LibratoMetrics.new('user', 'password',
                                                     :registry => registry)
    reporter.expects(:submit)
    reporter.write
  end
end
