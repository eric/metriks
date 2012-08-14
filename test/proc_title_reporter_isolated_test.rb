require 'test/unit'
require 'mocha'
require 'metriks/reporter/proc_title'

Thread.abort_on_exception = true

class ProcTitleReporterIsolatedTest < Test::Unit::TestCase
  def setup
    @original_proctitle = $0.dup
  end

  def teardown
    $0 = @original_proctitle
  end

  ### Options

  def test_specify_rounding
    reporter = Metriks::Reporter::ProcTitle.new :rounding => 2
    reporter.add('pi') { 3.1415926	}
    reporter.write
    assert_equal "#{ @original_proctitle } pi: 3.14", $0
  end

  def test_default_rounding
    reporter = Metriks::Reporter::ProcTitle.new
    reporter.add('pi') { 3.1415926	}
    reporter.write
    assert_equal "#{ @original_proctitle } pi: 3.1", $0
  end

  def test_ignore_rounding_for_non_floats
    reporter = Metriks::Reporter::ProcTitle.new
    reporter.add('pi') { '3.1415926'	}
    reporter.write
    assert_equal "#{ @original_proctitle } pi: 3.1415926", $0
  end

  def test_specify_prefix
    reporter = Metriks::Reporter::ProcTitle.new :prefix => 'metriks!'
    reporter.add('counter') { 1 }
    reporter.write
    assert_equal 'metriks! counter: 1', $0
  end

  def test_use_proctitle_for_default_prefix
    reporter = Metriks::Reporter::ProcTitle.new
    reporter.add('counter') { 1 }
    reporter.write
    assert_equal "#{ @original_proctitle } counter: 1", $0
  end

  # TODO: These tests don't really test the interval. Tie them in with #start
  # tests when written.
  def test_specify_interval
    Metriks::TimeTracker.expects(:new).with(42)
    Metriks::Reporter::ProcTitle.new(:interval => 42)
  end

  def test_default_interval_one_minute
    Metriks::TimeTracker.expects(:new).with(60)
    Metriks::Reporter::ProcTitle.new
  end

  def test_specify_error_handler
    Metriks::TimeTracker.any_instance.stubs(:sleep)
    handler = stub
    handler.expects(:[]).with(kind_of(RuntimeError)).at_least_once
    reporter = Metriks::Reporter::ProcTitle.new(:on_error => handler)
    def reporter.write() raise('write') end

    reporter.start
    sleep 0.01
    reporter.stop
  end

  def test_swallows_errors_raised_in_error_handler
    Metriks::TimeTracker.any_instance.stubs(:sleep)
    handler = stub do
      expects(:[]).raises(RuntimeError).at_least_once
    end
    reporter = Metriks::Reporter::ProcTitle.new(:on_error => handler)
    def reporter.write() raise('write') end

    reporter.start
    sleep 0.01
    reporter.stop
  end

  def test_default_error_handler_swallows_errors
    Metriks::TimeTracker.any_instance.stubs(:sleep)
    reporter = Metriks::Reporter::ProcTitle.new
    def reporter.write() raise('write') end

    reporter.start
    sleep 0.01
    reporter.stop
  end

  ### Public Methods

  def test_stop
    Metriks::TimeTracker.any_instance.stubs(:sleep)
    reporter = Metriks::Reporter::ProcTitle.new
    reporter.start
    sleep 0.01
    reporter.stop
    # Let some threads spawn and wait for them to die.
    wait = 0
    while Thread.list.size > 0
      wait += 1
      break if wait > 10
      sleep 0.01
    end
    reporter.expects(:write).never
    sleep 0.01
  end

  def test_stop_unstarted_reporter
    reporter = Metriks::Reporter::ProcTitle.new
    assert_nothing_raised { reporter.stop }
  end

  def test_empty_with_no_metrics
    reporter = Metriks::Reporter::ProcTitle.new
    assert reporter.empty?
  end

  def test_empty_with_metrics
    reporter = Metriks::Reporter::ProcTitle.new
    reporter.add 'counter'
    assert !reporter.empty?
  end

  def test_write_with_no_metrics
    Metriks::Reporter::ProcTitle.new.write
    assert_equal @original_proctitle, $0
  end

  def test_write
    reporter = Metriks::Reporter::ProcTitle.new
    reporter.add('counter') { 1 }
    reporter.write
    assert_equal "#{ @original_proctitle } counter: 1", $0
  end

  def test_writing_several_metrics
    reporter = Metriks::Reporter::ProcTitle.new
    reporter.add('counter') { 1 }
    reporter.add('pi') { 3.1415926	}
    reporter.write
    assert_equal "#{ @original_proctitle } counter: 1 pi: 3.1", $0
  end

  def test_metric_suffix
    reporter = Metriks::Reporter::ProcTitle.new
    reporter.add('counter', 'ms') { 1 }
    reporter.add('pi', '%')       { 3.1415926	}
    reporter.add('gold')          { 1.6180339 }
    reporter.write
    assert_equal "#{ @original_proctitle } counter: 1/ms pi: 3.1% gold: 1.6", $0
  end
end
