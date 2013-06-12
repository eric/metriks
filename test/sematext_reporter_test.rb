require 'test_helper'
require 'thread_error_handling_tests'

require 'metriks/reporter/sematext_metrics'

class SematextMetricsReporterTest < Test::Unit::TestCase
  include ThreadErrorHandlingTests

  def build_reporter(options={})
    @client = Sematext::Metrics::Client.sync('token')
    @reporter = Metriks::Reporter::SematextMetrics.new({
      :client => @client,
      :registry => @registry
    }.merge(options))
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
    @registry.meter('metriks-meter').mark
    @registry.counter('metriks-counter').increment
    @registry.timer('metriks-timer').update(1.5)
    @registry.histogram('metriks-histogram').update(1.5)
    @registry.utilization_timer('metriks-utilization-timer').update(1.5)
    @registry.gauge('metriks-gauge') { 42 }

    @client.expects(:send_batch).with() { |datapoints|
      assert_include datapoints, {
        :name => 'metriks-meter',
        :value => 1,
        :agg_type => :avg,
        :filter1 => "aggregation=avg",
        :filter2 => "type=count"
      }
      assert_include datapoints, {
        :name => 'metriks-counter',
        :value => 1,
        :agg_type => :avg,
        :filter1 => "aggregation=avg"
      }
      assert_include datapoints, {
        :name => 'metriks-timer',
        :value => 1.5,
        :agg_type => :max,
        :filter1 => "aggregation=max"
      }
      assert_include datapoints, {
        :name => 'metriks-histogram',
        :value => 1.5,
        :agg_type => :max,
        :filter1 => "aggregation=max"
      }
      assert_include datapoints, {
        :name => 'metriks-utilization-timer',
        :value => 1.5,
        :agg_type => :min,
        :filter1 => "aggregation=min"
      }
      assert_include datapoints, {
        :name => 'metriks-utilization-timer',
        :value => 1.5,
        :agg_type => :avg,
        :filter1 => "aggregation=avg",
        :filter2 => "type=time"
      }
      assert_include datapoints, {
        :name => 'metriks-gauge',
        :value => 42,
        :agg_type => :avg,
        :filter1 => "aggregation=avg"
      }
      true      
    }

    @reporter.write
  end

  private
  def assert_include(collection, element)
    assert_block("Element #{element} not found.") do
      collection.include? element
    end
  end
end
