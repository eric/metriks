require 'test_helper'

require 'metriks/gauge'

class GaugeTest < Test::Unit::TestCase
  def setup
    @gauge = Metriks::Gauge.new
  end

  def test_gauge
    3.times do |i|
      @gauge.set(i + 1)
    end

    assert_equal 3, @gauge.value

    @gauge.set(1)

    assert_equal 1, @gauge.value
  end

  def test_gauge_default
    assert_equal 0, @gauge.value
  end

  def test_gauge_callback_via_block
    @gauge.callback { 56 }

    assert_equal 56, @gauge.value
  end

  def test_gauge_callback_via_callable_object
    callable = Class.new(Struct.new(:value)) {
      def call
        value
      end
    }

    @gauge.callback(callable.new(987))

    assert_equal 987, @gauge.value

    @gauge.callback(proc { 123 })

    assert_equal 123, @gauge.value
  end
end
