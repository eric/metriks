require 'test_helper'

require 'metriks/meter'

class MeterTest < Test::Unit::TestCase
  include ThreadHelper

  def setup
    @meter = Metriks::Meter.new
  end

  def teardown
    @meter.stop
  end

  def test_meter
    @meter.mark

    assert_equal 1, @meter.count
  end

  def test_meter_threaded
    thread 10, :n => 100 do
      @meter.mark
    end

    assert_equal 1000, @meter.count
  end

  def test_one_minute_rate
    @meter.mark 1000

    # Pretend it's been 5 seconds
    @meter.tick

    assert_equal 200, @meter.one_minute_rate
  end

  def test_export_values
    @meter.mark 1000
    @meter.tick

    expected = {
     :count               => 1000,
     :one_minute_rate     => 200.0,
     :five_minute_rate    => 200.0,
     :fifteen_minute_rate => 200.0,
    }

    exported = @meter.export_values

    expected.each_pair do |metric, value|
      assert_equal value, exported[metric]
    end

    # This value changes wildly
    assert exported[:mean_rate] > 0
  end
end
