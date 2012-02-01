require 'test_helper'

require 'metriks/registry'

class RegistryTest < Test::Unit::TestCase
  def setup
    @registry = Metriks::Registry.new
  end

  def teardown
    @registry.stop
  end

  def test_counter
    assert_not_nil @registry.counter('testing')
  end

  def test_meter
    assert_not_nil @registry.meter('testing')
  end

  def test_timer
    assert_not_nil @registry.timer('testing')
  end

  def test_utilization_timer
    assert_not_nil @registry.utilization_timer('testing')
  end

  def test_calling_counter_twice
    assert_not_nil @registry.counter('testing')
  end

  def test_default
    assert_not_nil Metriks::Registry.default
  end
end