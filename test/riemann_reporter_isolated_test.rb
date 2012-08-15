require 'test/unit'
require 'mocha'
require 'metriks/reporter/riemann'

Thread.abort_on_exception = true

class RiemannReporterIsolatedTest < Test::Unit::TestCase
  ### Options

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
    Riemann::Client.expects(:new).
      with(:host => 'localhost', :port => 8080).
      returns(client)
    reporter = Metriks::Reporter::Riemann.new(:host     => 'localhost',
                                              :port     => 8080,
                                              :registry => registry)
    assert_equal client, reporter.client
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

  ### Public Methods

  def test_write
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
