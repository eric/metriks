require 'test_helper'

# riemann only works in 1.9
if RUBY_VERSION > '1.9'

require 'metriks/reporter/riemann'

class RiemannReporterTest < Test::Unit::TestCase
  def setup
    @registry = Metriks::Registry.new
    @reporter = Metriks::Reporter::Riemann.new(
      :host => "foo",
      :port => 1234,
      :registry => @registry,
      :default_event => {:host => "h"}
    )
  end

  def teardown
    @reporter.stop
    @registry.stop
  end

  def test_init
    assert_equal @reporter.client.host, "foo"
    assert_equal @reporter.client.port, 1234
  end

  def test_write
    @registry.meter('meter.testing').mark
    @registry.counter('counter.testing').increment
    @registry.timer('timer.testing').update(1.5)
    @registry.utilization_timer('utilization_timer.testing').update(1.5)

    @reporter.client.expects(:<<).at_least_once
    @reporter.client.expects(:<<).with(
      :host => "h",
      :service => "meter.testing count",
      :metric => 1,
      :tags => ["meter"],
      :ttl => 90
    )
    @reporter.client.expects(:<<).with(
      :host => "h",
      :service => "counter.testing count",
      :metric => 1,
      :tags => ["counter"],
      :ttl => 90
    )
    @reporter.client.expects(:<<).with(
      :host => "h",
      :service => "timer.testing max",
      :metric => 1.5,
      :tags => ["timer"],
      :ttl => 90
    )
    @reporter.client.expects(:<<).with(
      :host => "h",
      :service => "utilization_timer.testing mean",
      :metric => 1.5,
      :tags => ["utilization_timer"],
      :ttl => 90
    )

    @reporter.write
  end
end

end