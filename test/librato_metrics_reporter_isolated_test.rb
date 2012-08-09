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

  def test_prefix_option
    reporter = Metriks::Reporter::LibratoMetrics.
                 new('user', 'password', :prefix   => 'prefix',
                                         :registry => simple_registry)
    reporter.expects(:submit).
      with(has_entry('counters[0][name]' => 'prefix.registry.count'))
    reporter.write
    assert_equal 'prefix', reporter.prefix
  end

  def test_default_prefix_option
    reporter = Metriks::Reporter::LibratoMetrics.
                 new('user', 'password', :registry => simple_registry)
    reporter.expects(:submit).
      with(has_entry('counters[0][name]' => 'registry.count'))
    reporter.write
    assert_nil reporter.prefix
  end

  def test_source_option
    reporter = Metriks::Reporter::LibratoMetrics.
                 new('user', 'password', :source   => 'source',
                                         :registry => simple_registry)
    reporter.expects(:submit).
      with(has_entry('counters[0][source]' => 'source'))
    reporter.write
    assert_equal 'source', reporter.source
  end

  def test_default_source_option
    reporter = Metriks::Reporter::LibratoMetrics.
                 new('user', 'password', :registry => simple_registry)
    reporter.expects(:submit).with(Not(has_key('counters[0][source]')))
    reporter.write
    assert_nil reporter.source
  end

  def test_registry_option
    registry = stub
    registry.expects(:each)
    reporter = Metriks::Reporter::LibratoMetrics.
                 new('user', 'password', :registry => registry)
    reporter.write
  end

  def test_default_registry_option
    registry = stub
    registry.expects(:each)
    Metriks::Registry.expects(:default).returns(registry)
    Metriks::Reporter::LibratoMetrics.new('user', 'password').write
  end

  # TODO: These tests don't really test the interval. Tie them in with #start
  # tests when written.
  def test_interval_option
    Metriks::TimeTracker.expects(:new).with(42)
    Metriks::Reporter::LibratoMetrics.new('user', 'password', :interval => 42)
  end

  def test_default_interval_option
    Metriks::TimeTracker.expects(:new).with(60)
    Metriks::Reporter::LibratoMetrics.new('user', 'password')
  end

  def test_only_option
    registry = stub_iterator([ 'registry', stub_iterator([ 'one',   1.1 ])],
                             [ 'registry', stub_iterator([ 'two',   2.2 ],
                                                         [ 'three', 3.3 ]) ])
    matcher = stub
    matcher.expects(:===).with('registry.one').returns(true)
    matcher.expects(:===).with('registry.two').returns(false)
    matcher.expects(:===).with('registry.three').returns(true)

    expected = { 'gauges[0][name]' => 'registry.one',
                 'gauges[1][name]' => 'registry.three' }

    reporter = Metriks::Reporter::LibratoMetrics.
                 new('user', 'password', :registry => registry,
                                         :only     => [matcher])
    reporter.expects(:submit).with do |data|
      has_expected = expected.all? do |key, value|
        data.has_key?(key) && data[key] == value
      end
      has_no_extra_keys = !data.has_key?('gauges[2][name]')

      has_expected && has_no_extra_keys
    end

    reporter.write
  end

  def test_only_option_with_multiple_matchers
    registry = stub_iterator([ 'registry', stub_iterator([ 'one',   1.1 ])],
                             [ 'registry', stub_iterator([ 'two',   2.2 ],
                                                         [ 'three', 3.3 ]) ])
    matcher_one = stub :=== => false
    matcher_one.expects(:===).with('registry.one').returns(true)

    matcher_two = stub :=== => false
    matcher_two.expects(:===).with('registry.two').returns(true)

    expected = { 'gauges[0][name]' => 'registry.one',
                 'gauges[1][name]' => 'registry.two' }

    reporter = Metriks::Reporter::LibratoMetrics.
                 new('user', 'password', :registry => registry,
                                         :only     => [matcher_one, matcher_two])
    reporter.expects(:submit).with do |data|
      has_expected = expected.all? do |key, value|
        data.has_key?(key) && data[key] == value
      end
      has_no_extra_keys = !data.has_key?('gauges[2][name]')

      has_expected && has_no_extra_keys
    end

    reporter.write
  end

  def test_except_option
    registry = stub_iterator([ 'registry', stub_iterator([ 'one',   1.1 ])],
                             [ 'registry', stub_iterator([ 'two',   2.2 ],
                                                         [ 'three', 3.3 ]) ])
    matcher = stub
    matcher.expects(:===).with('registry.one').returns(true)
    matcher.expects(:===).with('registry.two').returns(false)
    matcher.expects(:===).with('registry.three').returns(true)

    expected = { 'gauges[0][name]' => 'registry.two' }
    reporter = Metriks::Reporter::LibratoMetrics.
                 new('user', 'password', :registry => registry,
                                         :except   => [matcher])
    reporter.expects(:submit).with do |data|
      has_expected = expected.all? do |key, value|
        data.has_key?(key) && data[key] == value
      end
      has_no_extra_keys = !data.has_key?('gauges[1][name]')

      has_expected && has_no_extra_keys
    end

    reporter.write
  end

  def test_except_option_with_multiple_matchers
    registry = stub_iterator([ 'registry', stub_iterator([ 'one',   1.1 ])],
                             [ 'registry', stub_iterator([ 'two',   2.2 ],
                                                         [ 'three', 3.3 ]) ])
    matcher_one = stub :=== => false
    matcher_one.expects(:===).with('registry.one').returns(true)

    matcher_two = stub :=== => false
    matcher_two.expects(:===).with('registry.two').returns(true)

    expected = { 'gauges[0][name]' => 'registry.three' }
    reporter = Metriks::Reporter::LibratoMetrics.
                 new('user', 'password', :registry => registry,
                                         :except   => [matcher_one, matcher_two])
    reporter.expects(:submit).with do |data|
      has_expected = expected.all? do |key, value|
        data.has_key?(key) && data[key] == value
      end
      has_no_extra_keys = !data.has_key?('gauges[1][name]')

      has_expected && has_no_extra_keys
    end

    reporter.write
  end

  def test_on_error_option
    handler = stub
    handler.expects(:[]).with(kind_of(RuntimeError)).at_least_once
    reporter = Metriks::Reporter::LibratoMetrics.new('user', 'password',
                                                    :interval => 0.001,
                                                    :on_error => handler)
    def reporter.write() raise('write') end

    reporter.start
    sleep 0.01
    reporter.stop
  end

  def test_on_error_option_swallows_handler_errors
    handler = stub
    handler.expects(:[]).raises(RuntimeError).at_least_once
    reporter = Metriks::Reporter::LibratoMetrics.new('user', 'password',
                                                    :interval => 0.001,
                                                    :on_error => handler)
    def reporter.write() raise('write') end

    reporter.start
    sleep 0.01
    reporter.stop
  end

  def test_default_on_error_option_swallows_errors
    reporter = Metriks::Reporter::LibratoMetrics.new('user', 'password',
                                                    :interval => 0.001)
    def reporter.write() raise('write') end

    reporter.start
    sleep 0.01
    reporter.stop
  end

  ### Public Methods

  def test_stop
    reporter = Metriks::Reporter::LibratoMetrics.new('user', 'password',
                                                    :interval => 0.001)
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
