require 'test_helper'
require 'thread_error_handling_tests'
require 'set'

require 'metriks/reporter/librato_metrics'

class LibratoMetricsReporterTest < Test::Unit::TestCase
  include ThreadErrorHandlingTests

  def build_reporter(options={})
    Metriks::Reporter::LibratoMetrics.new('user', 'password', { :registry => @registry }.merge(options))
  end

  def capture_report_names
    @actual_reports = SortedSet.new
    @reporter.expects(:submit).with do |data|
      data.each do |key, value|
        @actual_reports << value if key.end_with?('[name]')
      end
    end
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

    Metriks::TimeTracker.any_instance.stubs(:now_floored).returns('42')
    Metriks::Meter.any_instance.stubs(:mean_rate).returns('42')
    Metriks::UtilizationTimer.any_instance.stubs(:mean_utilization).returns('42')

    expected = { 'gauges[0][type]' => 'gauge',
                 'gauges[0][name]' => 'meter.testing.one_minute_rate',
                 'gauges[0][measure_time]' => '42',
                 'gauges[0][value]' => '0.0',
                 'gauges[1][type]' => 'gauge',
                 'gauges[1][name]' => 'meter.testing.five_minute_rate',
                 'gauges[1][measure_time]' => '42',
                 'gauges[1][value]' => '0.0',
                 'gauges[2][type]' => 'gauge',
                 'gauges[2][name]' => 'meter.testing.fifteen_minute_rate',
                 'gauges[2][measure_time]' => '42',
                 'gauges[2][value]' => '0.0',
                 'gauges[3][type]' => 'gauge',
                 'gauges[3][name]' => 'meter.testing.mean_rate',
                 'gauges[3][measure_time]' => '42',
                 'gauges[3][value]' => '42',

                 'gauges[4][type]' => 'gauge',
                 'gauges[4][name]' => 'timer.testing.one_minute_rate',
                 'gauges[4][measure_time]' => '42',
                 'gauges[4][value]' => '0.0',
                 'gauges[5][type]' => 'gauge',
                 'gauges[5][name]' => 'timer.testing.five_minute_rate',
                 'gauges[5][measure_time]' => '42',
                 'gauges[5][value]' => '0.0',
                 'gauges[6][type]' => 'gauge',
                 'gauges[6][name]' => 'timer.testing.fifteen_minute_rate',
                 'gauges[6][measure_time]' => '42',
                 'gauges[6][value]' => '0.0',
                 'gauges[7][type]' => 'gauge',
                 'gauges[7][name]' => 'timer.testing.mean_rate',
                 'gauges[7][measure_time]' => '42',
                 'gauges[7][value]' => '42',
                 'gauges[8][type]' => 'gauge',
                 'gauges[8][name]' => 'timer.testing.min',
                 'gauges[8][measure_time]' => '42',
                 'gauges[8][value]' => '1.5',
                 'gauges[9][type]' => 'gauge',
                 'gauges[9][name]' => 'timer.testing.max',
                 'gauges[9][measure_time]' => '42',
                 'gauges[9][value]' => '1.5',
                 'gauges[10][type]' => 'gauge',
                 'gauges[10][name]' => 'timer.testing.mean',
                 'gauges[10][measure_time]' => '42',
                 'gauges[10][value]' => '1.5',
                 'gauges[11][type]' => 'gauge',
                 'gauges[11][name]' => 'timer.testing.stddev',
                 'gauges[11][measure_time]' => '42',
                 'gauges[11][value]' => '0.0',
                 'gauges[12][type]' => 'gauge',
                 'gauges[12][name]' => 'timer.testing.median',
                 'gauges[12][measure_time]' => '42',
                 'gauges[12][value]' => '1.5',
                 'gauges[13][type]' => 'gauge',
                 'gauges[13][name]' => 'timer.testing.95th_percentile',
                 'gauges[13][measure_time]' => '42',
                 'gauges[13][value]' => '1.5',

                 'gauges[14][type]' => 'gauge',
                 'gauges[14][name]' => 'histogram.testing.min',
                 'gauges[14][measure_time]' => '42',
                 'gauges[14][value]' => '1.5',
                 'gauges[15][type]' => 'gauge',
                 'gauges[15][name]' => 'histogram.testing.max',
                 'gauges[15][measure_time]' => '42',
                 'gauges[15][value]' => '1.5',
                 'gauges[16][type]' => 'gauge',
                 'gauges[16][name]' => 'histogram.testing.mean',
                 'gauges[16][measure_time]' => '42',
                 'gauges[16][value]' => '1.5',
                 'gauges[17][type]' => 'gauge',
                 'gauges[17][name]' => 'histogram.testing.stddev',
                 'gauges[17][measure_time]' => '42',
                 'gauges[17][value]' => '0.0',
                 'gauges[18][type]' => 'gauge',
                 'gauges[18][name]' => 'histogram.testing.median',
                 'gauges[18][measure_time]' => '42',
                 'gauges[18][value]' => '1.5',
                 'gauges[19][type]' => 'gauge',
                 'gauges[19][name]' => 'histogram.testing.95th_percentile',
                 'gauges[19][measure_time]' => '42',
                 'gauges[19][value]' => '1.5',

                 'gauges[20][type]' => 'gauge',
                 'gauges[20][name]' => 'utilization_timer.testing.one_minute_rate',
                 'gauges[20][measure_time]' => '42',
                 'gauges[20][value]' => '0.0',
                 'gauges[21][type]' => 'gauge',
                 'gauges[21][name]' => 'utilization_timer.testing.five_minute_rate',
                 'gauges[21][measure_time]' => '42',
                 'gauges[21][value]' => '0.0',
                 'gauges[22][type]' => 'gauge',
                 'gauges[22][name]' => 'utilization_timer.testing.fifteen_minute_rate',
                 'gauges[22][measure_time]' => '42',
                 'gauges[22][value]' => '0.0',
                 'gauges[23][type]' => 'gauge',
                 'gauges[23][name]' => 'utilization_timer.testing.mean_rate',
                 'gauges[23][measure_time]' => '42',
                 'gauges[23][value]' => '42',
                 'gauges[24][type]' => 'gauge',
                 'gauges[24][name]' => 'utilization_timer.testing.min',
                 'gauges[24][measure_time]' => '42',
                 'gauges[24][value]' => '1.5',
                 'gauges[25][type]' => 'gauge',
                 'gauges[25][name]' => 'utilization_timer.testing.max',
                 'gauges[25][measure_time]' => '42',
                 'gauges[25][value]' => '1.5',
                 'gauges[26][type]' => 'gauge',
                 'gauges[26][name]' => 'utilization_timer.testing.mean',
                 'gauges[26][measure_time]' => '42',
                 'gauges[26][value]' => '1.5',
                 'gauges[27][type]' => 'gauge',
                 'gauges[27][name]' => 'utilization_timer.testing.stddev',
                 'gauges[27][measure_time]' => '42',
                 'gauges[27][value]' => '0.0',
                 'gauges[28][type]' => 'gauge',
                 'gauges[28][name]' => 'utilization_timer.testing.one_minute_utilization',
                 'gauges[28][measure_time]' => '42',
                 'gauges[28][value]' => '0.0',
                 'gauges[29][type]' => 'gauge',
                 'gauges[29][name]' => 'utilization_timer.testing.five_minute_utilization',
                 'gauges[29][measure_time]' => '42',
                 'gauges[29][value]' => '0.0',
                 'gauges[30][type]' => 'gauge',
                 'gauges[30][name]' => 'utilization_timer.testing.fifteen_minute_utilization',
                 'gauges[30][measure_time]' => '42',
                 'gauges[30][value]' => '0.0',
                 'gauges[31][type]' => 'gauge',
                 'gauges[31][name]' => 'utilization_timer.testing.mean_utilization',
                 'gauges[31][measure_time]' => '42',
                 'gauges[31][value]' => '42',
                 'gauges[32][type]' => 'gauge',
                 'gauges[32][name]' => 'utilization_timer.testing.median',
                 'gauges[32][measure_time]' => '42',
                 'gauges[32][value]' => '1.5',
                 'gauges[33][type]' => 'gauge',
                 'gauges[33][name]' => 'utilization_timer.testing.95th_percentile',
                 'gauges[33][measure_time]' => '42',
                 'gauges[33][value]' => '1.5',

                 'counters[0][type]' => 'counter',
                 'counters[0][name]' => 'meter.testing.count',
                 'counters[0][measure_time]' => '42',
                 'counters[0][value]' => '1',
                 'counters[1][type]' => 'counter',
                 'counters[1][name]' => 'counter.testing.count',
                 'counters[1][measure_time]' => '42',
                 'counters[1][value]' => '1',
                 'counters[2][type]' => 'counter',
                 'counters[2][name]' => 'timer.testing.count',
                 'counters[2][measure_time]' => '42',
                 'counters[2][value]' => '1',
                 'counters[3][type]' => 'counter',
                 'counters[3][name]' => 'histogram.testing.count',
                 'counters[3][measure_time]' => '42',
                 'counters[3][value]' => '1',
                 'counters[4][type]' => 'counter',
                 'counters[4][name]' => 'utilization_timer.testing.count',
                 'counters[4][measure_time]' => '42',
                 'counters[4][value]' => '1' }

    @reporter.expects(:submit).with(expected)

    @reporter.write
  end

  def test_report_gauges
    @registry.meter('meter.testing').mark
    @registry.counter('counter.testing').increment

    reports = SortedSet.new %w( meter.testing.one_minute_rate counter.testing.count )
    @reporter = build_reporter :only => reports
    capture_report_names
    @reporter.write

    assert_equal reports, @actual_reports
  end

  def test_omit_gauges
    @registry.meter('meter.testing').mark
    @registry.counter('counter.testing').increment

    @reporter = build_reporter :except => %w( meter.testing.one_minute_rate
                                              counter.testing.count )
    capture_report_names
    @reporter.write

    expected_reports = SortedSet.new %w( meter.testing.five_minute_rate
                                         meter.testing.fifteen_minute_rate
                                         meter.testing.mean_rate
                                         meter.testing.count )

    assert_equal expected_reports, @actual_reports
  end

  def test_report_gauges_by_regex
    @registry.meter('meter.testing').mark
    @registry.counter('counter.testing').increment

    @reporter = build_reporter :only => [ /.*\.count/ ]
    capture_report_names
    @reporter.write

    expected_reports = SortedSet.new %w( meter.testing.count
                                         counter.testing.count )

    assert_equal expected_reports, @actual_reports
  end

  def test_omit_gauges_by_regex
    @registry.meter('meter.testing').mark
    @registry.counter('counter.testing').increment

    @reporter = build_reporter :except => [ /.*\.count/ ]
    capture_report_names
    @reporter.write

    expected_reports = SortedSet.new %w( meter.testing.one_minute_rate
                                         meter.testing.five_minute_rate
                                         meter.testing.fifteen_minute_rate
                                         meter.testing.mean_rate )

    assert_equal expected_reports, @actual_reports
  end
end
