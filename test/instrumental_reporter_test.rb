require 'test_helper'
require 'thread_error_handling_tests'

require 'metriks/reporter/instrumental'

class InstrumentalReporterTest < Test::Unit::TestCase
  include ThreadErrorHandlingTests

  def build_reporter(options = {})
    options[:agent] ||= Instrumental::Agent.new('SOME_TOKEN', :enabled => false)
    Metriks::Reporter::Instrumental.new({ :registry => @registry }.merge(options))
  end

  def setup
    @registry = Metriks::Registry.new
    @reporter = build_reporter
    @agent    = @reporter.agent
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

    @agent.expects(:gauge).at_least(4)
    @agent.expects(:increment).at_least(1)
    @reporter.write
  end
end
