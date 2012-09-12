require 'test_helper'

require 'metriks/derive'

class DeriveTest < Test::Unit::TestCase
  include ThreadHelper

  def setup
    @meter = Metriks::Derive.new
  end

  def teardown
    @meter.stop
  end

  def test_meter
    @meter.mark(100)
    @meter.mark(150)

    assert_equal 50, @meter.count
  end

  def test_one_minute_rate
    @meter.mark(1000)
    @meter.mark(2000)

    # Pretend it's been 5 seconds
    @meter.tick

    assert_equal 200, @meter.one_minute_rate
  end
end
