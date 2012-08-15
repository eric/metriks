require 'test/unit'
require 'mocha'
require 'metriks/reporter/librato_metrics'

Thread.abort_on_exception = true

class LibratoMetricsReporterIsolatedTest < Test::Unit::TestCase
  ### Options

  def test_prefix_metric_names
    metric = stub do
      stubs(:each).yields([ 'count', 1 ])
    end
    registry = stub do
      stubs(:each).yields('counter', metric)
    end
    reporter = Metriks::Reporter::LibratoMetrics.new('user', 'password',
                                                     :prefix   => 'prefix',
                                                     :registry => registry)
    reporter.expects(:submit).
      with(has_entry('counters[0][name]' => 'prefix.counter.count'))
    reporter.write
    assert_equal 'prefix', reporter.prefix
  end

  def test_no_prefix_by_default
    metric = stub do
      stubs(:each).yields([ 'count', 1 ])
    end
    registry = stub do
      stubs(:each).yields('counter', metric)
    end
    reporter = Metriks::Reporter::LibratoMetrics.new('user', 'password',
                                                     :registry => registry)
    reporter.expects(:submit).
      with(has_entry('counters[0][name]' => 'counter.count'))
    reporter.write
    assert_nil reporter.prefix
  end

  def test_record_source
    metric = stub do
      stubs(:each).yields([ 'count', 1 ])
    end
    registry = stub do
      stubs(:each).yields('counter', metric)
    end
    reporter = Metriks::Reporter::LibratoMetrics.new('user', 'password',
                                                     :source   => 'source',
                                                     :registry => registry)
    reporter.expects(:submit).
      with(has_entry('counters[0][source]' => 'source'))
    reporter.write
    assert_equal 'source', reporter.source
  end

  def test_default_source_is_omitted
    metric = stub do
      stubs(:each).yields([ 'count', 1 ])
    end
    registry = stub do
      stubs(:each).yields('counter', metric)
    end
    reporter = Metriks::Reporter::LibratoMetrics.new('user', 'password',
                                                     :registry => registry)
    reporter.expects(:submit).with(Not(has_key('counters[0][source]')))
    reporter.write
    assert_nil reporter.source
  end

  def test_report_only_matching_metric
    metric_one = stub do
      stubs(:each).yields([ 'one', 1.1 ])
    end
    metric_two = stub do
      stubs(:each).multiple_yields([ 'two',   2.2 ],
                                   [ 'three', 3.3 ])
    end
    registry = stub do
      stubs(:each).multiple_yields([ 'metric_one', metric_one ],
                                   [ 'metric_two', metric_two ])
    end
    reporter = Metriks::Reporter::LibratoMetrics.
                 new('user', 'password', :registry => registry,
                                         :only     => ['metric_one.one'])
    reporter.expects(:submit).with do |data|
      data.has_key?('gauges[0][name]')    &&
        !data.has_key?('gauges[1][name]') &&
        !data.has_key?('gauges[2][name]') &&
        data['gauges[0][name]'] == 'metric_one.one'
    end
    reporter.write
  end

  def test_report_only_several_matching_metric
    metric_one = stub do
      stubs(:each).yields([ 'one', 1.1 ])
    end
    metric_two = stub do
      stubs(:each).multiple_yields([ 'two',   2.2 ],
                                   [ 'three', 3.3 ])
    end
    registry = stub do
      stubs(:each).multiple_yields([ 'metric_one', metric_one ],
                                   [ 'metric_two', metric_two ])
    end
    reporter = Metriks::Reporter::LibratoMetrics.
                 new('user', 'password', :registry => registry,
                                         :only     => %w( metric_one.one
                                                          metric_two.three ))
    reporter.expects(:submit).with do |data|
      data.has_key?('gauges[0][name]')    &&
        data.has_key?('gauges[1][name]')  &&
        !data.has_key?('gauges[2][name]') &&
        data['gauges[0][name]'] == 'metric_one.one' &&
        data['gauges[1][name]'] == 'metric_two.three'
    end
    reporter.write
  end

  def test_only_matches_using_threequals_operator
    metric_one = stub do
      stubs(:each).yields([ 'one', 1.1 ])
    end
    metric_two = stub do
      stubs(:each).multiple_yields([ 'two',   2.2 ],
                                   [ 'three', 3.3 ])
    end
    registry = stub do
      stubs(:each).multiple_yields([ 'metric_one', metric_one ],
                                   [ 'metric_two', metric_two ])
    end
    matcher = stub
    matcher.expects(:===).with('metric_one.one')
    matcher.expects(:===).with('metric_two.two')
    matcher.expects(:===).with('metric_two.three')
    reporter = Metriks::Reporter::LibratoMetrics.new('user', 'password',
                                                     :registry => registry,
                                                     :only     => [matcher])
    reporter.write
  end

  def test_report_except_matching_metric
    metric_one = stub do
      stubs(:each).yields([ 'one', 1.1 ])
    end
    metric_two = stub do
      stubs(:each).multiple_yields([ 'two',   2.2 ],
                                   [ 'three', 3.3 ])
    end
    registry = stub do
      stubs(:each).multiple_yields([ 'metric_one', metric_one ],
                                   [ 'metric_two', metric_two ])
    end
    reporter = Metriks::Reporter::LibratoMetrics.
                 new('user', 'password', :registry => registry,
                                         :except   => ['metric_one.one'])
    reporter.expects(:submit).with do |data|
      data.has_key?('gauges[0][name]')    &&
        data.has_key?('gauges[1][name]')  &&
        !data.has_key?('gauges[2][name]') &&
        data['gauges[0][name]'] == 'metric_two.two' &&
        data['gauges[1][name]'] == 'metric_two.three'
    end
    reporter.write
  end

  def test_report_except_several_matching_metric
    metric_one = stub do
      stubs(:each).yields([ 'one', 1.1 ])
    end
    metric_two = stub do
      stubs(:each).multiple_yields([ 'two',   2.2 ],
                                   [ 'three', 3.3 ])
    end
    registry = stub do
      stubs(:each).multiple_yields([ 'metric_one', metric_one ],
                                   [ 'metric_two', metric_two ])
    end
    reporter = Metriks::Reporter::LibratoMetrics.
                 new('user', 'password', :registry => registry,
                                         :except   => %w( metric_one.one
                                                          metric_two.three ))
    reporter.expects(:submit).with do |data|
      data.has_key?('gauges[0][name]')    &&
        !data.has_key?('gauges[1][name]') &&
        !data.has_key?('gauges[2][name]') &&
        data['gauges[0][name]'] == 'metric_two.two'
    end
    reporter.write
  end

  def test_except_matches_using_threequals_operator
    metric_one = stub do
      stubs(:each).yields([ 'one', 1.1 ])
    end
    metric_two = stub do
      stubs(:each).multiple_yields([ 'two',   2.2 ],
                                   [ 'three', 3.3 ])
    end
    registry = stub do
      stubs(:each).multiple_yields([ 'metric_one', metric_one ],
                                   [ 'metric_two', metric_two ])
    end
    matcher = stub
    matcher.expects(:===).with('metric_one.one')
    matcher.expects(:===).with('metric_two.two')
    matcher.expects(:===).with('metric_two.three')
    reporter = Metriks::Reporter::LibratoMetrics.new('user', 'password',
                                                     :registry => registry,
                                                     :except   => [matcher])
    reporter.stubs(:submit)
    reporter.write
  end

  ### Public Methods

  def test_write
    Metriks::TimeTracker.any_instance.stubs(:now_floored).returns(42)
    metric = stub do
      stubs(:each).yields([ 'one', 1.1 ])
    end
    registry = stub do
      stubs(:each).yields([ 'metric', metric ])
    end
    reporter = Metriks::Reporter::LibratoMetrics.new('user', 'password',
                                                     :registry => registry)
    expected = { 'gauges[0][type]'         => 'gauge',
                 'gauges[0][name]'         => 'metric.one',
                 'gauges[0][measure_time]' => '42',
                 'gauges[0][value]'        => '1.1' }
    reporter.expects(:submit).with(expected)
    reporter.write
  end

  def test_write_several_metrics
    metric_one = stub do
      stubs(:each).yields([ 'one', 1.1 ])
    end
    metric_two = stub do
      stubs(:each).multiple_yields([ 'two',   2.2 ],
                                   [ 'three', 3.3 ])
    end
    registry = stub do
      stubs(:each).multiple_yields([ 'metric_one', metric_one ],
                                   [ 'metric_two', metric_two ])
    end
    reporter = Metriks::Reporter::LibratoMetrics.new('user', 'password',
                                                     :registry => registry)
    expected = { 'gauges[0][name]'  => 'metric_one.one',
                 'gauges[0][value]' => '1.1',
                 'gauges[1][name]'  => 'metric_two.two',
                 'gauges[1][value]' => '2.2',
                 'gauges[2][name]'  => 'metric_two.three',
                 'gauges[2][value]' => '3.3' }
    reporter.expects(:submit).with(has_entries(expected))
    reporter.write
  end

  def test_write_counters
    metric = stub do
      stubs(:each).yields([ 'count', 1 ])
    end
    registry = stub do
      stubs(:each).yields([ 'metric', metric ])
    end
    reporter = Metriks::Reporter::LibratoMetrics.new('user', 'password',
                                                     :registry => registry)
    expected = { 'counters[0][type]' => 'counter' }
    reporter.expects(:submit).with(has_entries(expected))
    reporter.write
  end

  def test_write_records_times_once_per_write
    Metriks::TimeTracker.any_instance.stubs(:now_floored).returns(42).once
    metric_one = stub do
      stubs(:each).yields([ 'one', 1.1 ])
    end
    metric_two = stub do
      stubs(:each).multiple_yields([ 'two',   2.2 ],
                                   [ 'three', 3.3 ])
    end
    registry = stub do
      stubs(:each).multiple_yields([ 'metric_one', metric_one ],
                                   [ 'metric_two', metric_two ])
    end
    reporter = Metriks::Reporter::LibratoMetrics.new('user', 'password',
                                                     :registry => registry)
    reporter.expects(:submit)
    reporter.write
  end
end
