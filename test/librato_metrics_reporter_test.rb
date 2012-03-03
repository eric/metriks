require 'test_helper'

require 'metriks/reporter/librato_metrics'

class LibratoMetricsReporterTest < Test::Unit::TestCase
  def setup
    @registry = Metriks::Registry.new
    @reporter = Metriks::Reporter::LibratoMetrics.new('user', 'password', :registry => @registry)

    @reporter.connection.builder.tap do |c|
      c.swap 1, Faraday::Adapter::Test do |stub|
        stub.post '/v1/metrics' do |env|
          [ 200, {}, '' ]
        end
      end
    end
  end

  def teardown
    @reporter.stop
    @registry.stop
  end

  def test_write
    @registry.meter('meter.testing').mark
    @registry.counter('counter.testing').increment
    @registry.timer('timer.testing').update(1.5)
    @registry.utilization_timer('utilization_timer.testing').update(1.5)

    @reporter.write
  end
end