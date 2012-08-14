require 'test/unit'
require 'mocha'
require 'metriks/reporter/riemann'

Thread.abort_on_exception = true

class RiemannReporterIsolatedTest < Test::Unit::TestCase
  ### Options

  def test_specify_connection_details
    client = stub
    Riemann::Client.expects(:new).
      with(:host => 'localhost', :port => 8080).
      returns(client)
    reporter = Metriks::Reporter::Riemann.new(:host => 'localhost',
                                              :port => 8080)
    assert_equal client, reporter.client
  end

  def test_assign_client
    reporter = Metriks::Reporter::Riemann.new(:host => 'localhost',
                                              :port => 8080)
    client = stub
    reporter.client = client
    assert_equal client, reporter.client
  end

  def test_use_connection_details
    metric = stub do
      stubs :type => 'counter'
      stubs(:each).yields([ 'count', 1 ])
    end
    registry = stub do
      stubs(:each).yields('testing', metric)
    end
    client = stub { expects(:<<) }
    Riemann::Client.stubs(:new).returns(client)
    reporter = Metriks::Reporter::Riemann.new(:host     => 'localhost',
                                              :port     => 8080,
                                              :registry => registry)
    reporter.write
  end

  def test_default_event_without_ttl
    metric = stub do
      stubs :type => 'counter'
      stubs(:each).yields([ 'count', 1 ])
    end
    registry = stub do
      stubs(:each).yields('testing', metric)
    end
    client = stub
    client.expects(:<<).with(has_entries(:test => 42, :ttl => 90.0))
    Riemann::Client.stubs(:new).returns(client)
    reporter = Metriks::Reporter::Riemann.new(:host => 'localhost',
                                              :port => 8080,
                                              :registry      => registry,
                                              :default_event => { :test => 42 })
    reporter.write
  end

  def test_default_event_with_ttl
    metric = stub do
      stubs :type => 'counter'
      stubs(:each).yields([ 'count', 1 ])
    end
    registry = stub do
      stubs(:each).yields('testing', metric)
    end
    client = stub
    client.expects(:<<).with(has_entries(:test => 42, :ttl => 24))
    Riemann::Client.stubs(:new).returns(client)
    reporter = Metriks::Reporter::Riemann.new(:host => 'localhost',
                                              :port => 8080,
                                              :registry      => registry,
                                              :default_event => { :test => 42,
                                                                  :ttl  => 24 })
    reporter.write
  end

  def test_specify_registry
    registry = stub { expects(:each) }
    reporter = Metriks::Reporter::Riemann.new(:host     => 'localhost',
                                              :port     => 8080,
                                              :registry => registry)
    reporter.write
  end

  def test_uses_default_registry
    registry = stub { expects(:each) }
    Metriks::Registry.expects(:default).returns(registry)
    reporter = Metriks::Reporter::Riemann.new(:host => 'localhost',
                                              :port => 8080)
    reporter.write
  end

  # TODO: These tests don't really test the interval. Tie them in with #start
  # tests when written.
  def test_specify_interval
    Metriks::TimeTracker.expects(:new).with(42)
    Metriks::Reporter::Riemann.new(:host => 'localhost', :port => 8080, :interval => 42)
  end

  def test_default_interval_one_minute
    Metriks::TimeTracker.expects(:new).with(60)
    Metriks::Reporter::Riemann.new(:host => 'localhost', :port => 8080)
  end

  def test_specify_error_handler
    Metriks::TimeTracker.any_instance.stubs(:sleep)
    handler = stub
    handler.expects(:[]).with(kind_of(RuntimeError)).at_least_once
    reporter = Metriks::Reporter::Riemann.new(:host     => 'localhost',
                                              :port     => 8080,
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
    reporter = Metriks::Reporter::Riemann.new(:host     => 'localhost',
                                              :port     => 8080,
                                              :on_error => handler)
    def reporter.write() raise('write') end

    reporter.start
    sleep 0.01
    reporter.stop
  end

  def test_default_error_handler_swallows_errors
    Metriks::TimeTracker.any_instance.stubs(:sleep)
    reporter = Metriks::Reporter::Riemann.new(:host => 'localhost',
                                              :port => 8080)
    def reporter.write() raise('write') end

    reporter.start
    sleep 0.01
    reporter.stop
  end

  ### Public Methods

  def test_stop
    Metriks::TimeTracker.any_instance.stubs(:sleep)
    reporter = Metriks::Reporter::Riemann.new(:host => 'localhost',
                                              :port => 8080)
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
    reporter = Metriks::Reporter::Riemann.new(:host => 'localhost',
                                              :port => 8080)
    assert_nothing_raised { reporter.stop }
  end

  def test_write
    Time.stubs(:now => 42)
    metric = stub do
      stubs :type => 'counter'
      stubs(:each).yields([ 'count', 1 ])
    end
    registry = stub do
      stubs(:each).yields('testing', metric)
    end
    client = stub {
      expected = { :ttl     => 90,
                   :service => 'testing count',
                   :metric  => 1,
                   :tags    => ['counter']
                 }
      expects(:<<).with(expected)
    }
    Riemann::Client.stubs(:new).returns(client)
    reporter = Metriks::Reporter::Riemann.new(:host     => 'localhost',
                                              :port     => 8080,
                                              :registry => registry)
    reporter.write
  end

  def test_writes_multiple_metrics
    Time.stubs(:now => 42)
    metric_one = stub do
      stubs :type => 'one'
      stubs(:each).yields([ 'one', 1.1 ])
    end
    metric_two = stub do
      stubs :type => 'two'
      stubs(:each).multiple_yields([ 'two',   2.2 ],
                                   [ 'three', 3.3 ])
    end
    registry = stub do
      stubs(:each).multiple_yields([ 'metric_one', metric_one ],
                                   [ 'metric_two', metric_two ])
    end
    client = stub {
      expects(:<<).with(:ttl     => 90,
                        :service => 'metric_one one',
                        :metric  => 1.1,
                        :tags    => ['one'])
      expects(:<<).with(:ttl     => 90,
                        :service => 'metric_two two',
                        :metric  => 2.2,
                        :tags    => ['two'])
      expects(:<<).with(:ttl     => 90,
                        :service => 'metric_two three',
                        :metric  => 3.3,
                        :tags    => ['two'])
    }
    Riemann::Client.stubs(:new).returns(client)
    reporter = Metriks::Reporter::Riemann.new(:host     => 'localhost',
                                              :port     => 8080,
                                              :registry => registry)
    reporter.write
  end
end
