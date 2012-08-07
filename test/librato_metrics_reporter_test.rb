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

    @reporter.expects(:submit)

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
