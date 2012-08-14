require 'test/unit'
require 'mocha'
require 'metriks/reporter/graphite'

Thread.abort_on_exception = true

class GraphiteReporterIsolatedTest < Test::Unit::TestCase
  ### Options

  def test_specify_connection_details
    reporter = Metriks::Reporter::Graphite.new('localhost', 8080)
    assert_equal 'localhost', reporter.host
    assert_equal 8080, reporter.port
  end

  def test_assign_connection_details
    reporter = Metriks::Reporter::Graphite.new('localhost', 8080)
    reporter.host = 'remotehost'
    reporter.port = 24
    assert_equal 'remotehost', reporter.host
    assert_equal 24, reporter.port
  end

  def test_use_connection
    metric = stub do
      stubs(:each).yields([ 'count', 1 ])
    end
    registry = stub do
      stubs(:each).yields('testing', metric)
    end
    reporter = Metriks::Reporter::Graphite.new('localhost', 8080,
                                               :registry => registry)
    socket = stub { stubs(:write) }
    TCPSocket.expects(:new).with('localhost', 8080).returns(socket)
    reporter.write
  end

  def test_reuses_connection
    metric = stub do
      stubs(:each).yields([ 'count', 1 ])
    end
    registry = stub do
      stubs(:each).yields('testing', metric)
    end
    reporter = Metriks::Reporter::Graphite.new('localhost', 8080,
                                               :registry => registry)
    socket = stub do
      stubs(:closed?).returns(false)
      expects(:write).times(3)
    end
    TCPSocket.expects(:new).with('localhost', 8080).once.returns(socket)
    3.times { reporter.write }
  end

  def test_creates_new_connection_when_closed
    metric = stub do
      stubs(:each).yields([ 'count', 1 ])
    end
    registry = stub do
      stubs(:each).yields('testing', metric)
    end
    reporter = Metriks::Reporter::Graphite.new('localhost', 8080,
                                               :registry => registry)
    socket = stub do
      expects(:write).once
    end
    TCPSocket.stubs(:new).with('localhost', 8080).returns(socket)
    reporter.write

    socket.stubs(:closed?).returns(true)
    new_socket = stub do
      expects(:write).once
    end
    TCPSocket.stubs(:new).with('localhost', 8080).returns(new_socket)
    reporter.write
  end

  def test_specify_prefix
    reporter = Metriks::Reporter::Graphite.new('localhost', 8080,
                                               :prefix => 'prefix')
    assert_equal 'prefix', reporter.prefix
  end

  def test_no_default_prefix
    reporter = Metriks::Reporter::Graphite.new('localhost', 8080)
    assert_nil reporter.prefix
  end

  def test_assign_prefix
    reporter = Metriks::Reporter::Graphite.new('localhost', 8080)
    reporter.prefix = 'prefix'
    assert_equal 'prefix', reporter.prefix
  end

  def test_use_prefix
    Time.stubs(:now => 42)
    metric = stub do
      stubs(:each).yields([ 'count', 1 ])
    end
    registry = stub do
      stubs(:each).yields('testing', metric)
    end
    reporter = Metriks::Reporter::Graphite.new('localhost', 8080,
                                               :registry => registry,
                                               :prefix   => 'prefix')
    socket = stub do
      expects(:write).with("prefix.testing.count 1 42\n")
    end
    reporter.stubs(:socket).returns(socket)
    reporter.write
  end

  def test_specify_registry
    registry = stub { expects(:each) }
    reporter = Metriks::Reporter::Graphite.new('localhost', 8080,
                                               :registry => registry)
    reporter.write
  end

  def test_uses_default_registry
    registry = stub { expects(:each) }
    Metriks::Registry.expects(:default).returns(registry)
    reporter = Metriks::Reporter::Graphite.new('localhost', 8080)
    reporter.write
  end

  # TODO: These tests don't really test the interval. Tie them in with #start
  # tests when written.
  def test_specify_interval
    Metriks::TimeTracker.expects(:new).with(42)
    Metriks::Reporter::Graphite.new('localhost', 8080, :interval => 42)
  end

  def test_default_interval_one_minute
    Metriks::TimeTracker.expects(:new).with(60)
    Metriks::Reporter::Graphite.new('localhost', 8080)
  end

  def test_specify_error_handler
    Metriks::TimeTracker.any_instance.stubs(:sleep)
    handler = stub
    handler.expects(:[]).with(kind_of(RuntimeError)).at_least_once
    reporter = Metriks::Reporter::Graphite.new('localhost', 8080,
                                               :on_error => handler)
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
    reporter = Metriks::Reporter::Graphite.new('localhost', 8080,
                                               :on_error => handler)
    def reporter.write() raise('write') end

    reporter.start
    sleep 0.01
    reporter.stop
  end

  def test_default_error_handler_swallows_errors
    Metriks::TimeTracker.any_instance.stubs(:sleep)
    reporter = Metriks::Reporter::Graphite.new('localhost', 8080)
    def reporter.write() raise('write') end

    reporter.start
    sleep 0.01
    reporter.stop
  end

  ### Public Methods

  def test_stop
    Metriks::TimeTracker.any_instance.stubs(:sleep)
    reporter = Metriks::Reporter::Graphite.new('localhost', 8080)
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
    reporter = Metriks::Reporter::Graphite.new('localhost', 8080)
    assert_nothing_raised { reporter.stop }
  end

  def test_write
    Time.stubs(:now => 42)
    metric = stub do
      stubs(:each).yields([ 'count', 1 ])
    end
    registry = stub do
      stubs(:each).yields('testing', metric)
    end
    reporter = Metriks::Reporter::Graphite.new('localhost', 8080,
                                               :registry => registry)
    socket = stub do
      expects(:write).with("testing.count 1 42\n")
    end
    reporter.stubs(:socket).returns(socket)
    reporter.write
  end

  def test_writes_multiple_metrics
    Time.stubs(:now => 42)
    logger = stub :logger
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
    reporter = Metriks::Reporter::Graphite.new('localhost', 8080,
                                               :registry => registry)
    socket = stub do
      expects(:write).with("metric_one.one 1.1 42\n")
      expects(:write).with("metric_two.two 2.2 42\n")
      expects(:write).with("metric_two.three 3.3 42\n")
    end
    reporter.stubs(:socket).returns(socket)
    reporter.write
  end

  def test_write_records_times_once_per_write
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
    reporter = Metriks::Reporter::Graphite.new('localhost', 8080,
                                               :registry => registry)
    socket = stub do
      expects(:write).at_least_once
    end
    reporter.stubs(:socket).returns(socket)
    time = stub do
      expects(:to_i).at_least_once.returns(42)
    end
    Time.expects(:now).once.returns(time)
    reporter.write
  end
end
