require 'test/unit'
require 'mocha'
require 'metriks/reporter'

Thread.abort_on_exception = true

class ReporterTest < Test::Unit::TestCase
  ## Options

  # TODO: These tests don't really test the interval. Tie them in with #start
  # tests when written.
  def test_specify_interval
    Metriks::TimeTracker.expects(:new).with(42)
    Metriks::Reporter.new(:interval => 42)
  end

  def test_default_interval_one_minute
    Metriks::TimeTracker.expects(:new).with(60)
    Metriks::Reporter.new
  end

  def test_specify_error_handler
    Metriks::TimeTracker.any_instance.stubs(:sleep)
    handler = stub
    handler.expects(:[]).with(kind_of(RuntimeError)).at_least_once
    reporter = Metriks::Reporter.new(:on_error => handler)
    def reporter.write() raise('write') end

    reporter.start
    sleep 0.01
    reporter.stop
  end

  def test_swallows_errors_raised_in_error_handler
    Metriks::TimeTracker.any_instance.stubs(:sleep)
    handler = stub
    handler.expects(:[]).raises(RuntimeError).at_least_once
    reporter = Metriks::Reporter.new(:on_error => handler)
    def reporter.write() raise('write') end

    reporter.start
    sleep 0.01
    reporter.stop
  end

  def test_default_error_handler_swallows_errors
    Metriks::TimeTracker.any_instance.stubs(:sleep)
    reporter = Metriks::Reporter.new
    def reporter.write() raise('write') end

    reporter.start
    sleep 0.01
    reporter.stop
  end

  def test_specify_registry
    registry = stub
    reporter = Metriks::Reporter.new(:registry => registry)
    assert_equal registry, reporter.registry
  end

  def test_uses_default_registry
    registry = stub
    Metriks::Registry.expects(:default).returns(registry)
    reporter = Metriks::Reporter.new
    assert_equal registry, reporter.registry
  end

  ### Public Methods

  def test_start
  end

  def test_stop
    Metriks::TimeTracker.any_instance.stubs(:sleep)
    reporter = Metriks::Reporter.new
    reporter.start
    sleep 0.01  # Let some reporting threads spawn.
    reporter.stop
    wait = 0
    while Thread.list.size > 0  # Wait for reporting threads to die.
      wait += 1
      break if wait > 10
      sleep 0.01
    end
    reporter.expects(:write).never
    sleep 0.01
  end

  def test_stop_unstarted_reporter
    reporter = Metriks::Reporter.new
    assert_nothing_raised { reporter.stop }
  end

  def test_restart
  end
end
