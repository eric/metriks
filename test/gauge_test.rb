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
end
