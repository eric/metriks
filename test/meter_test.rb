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

  def test_has_no_reportable_snapshot_metrics
    assert_equal [], Metriks::Meter.reportable_snapshot_metrics
  end

  def test_has_reportable_metrics
    assert_not_empty Metriks::Meter.reportable_metrics
  end
end
