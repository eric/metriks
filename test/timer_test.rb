require 'test_helper'

require 'metriks/timer'

class TimerTest < Test::Unit::TestCase
  def setup
    @timer = Metriks::Timer.new
  end

  def teardown
    @timer.stop
  end

  def test_timer
    @timer.time do
      sleep 0.1
    end

    assert_in_delta 0.1, @timer.mean, 0.01
  end

  def test_timer_without_block
    t = @timer.time
    sleep 0.1
    t.stop

    assert_in_delta 0.1, @timer.mean, 0.01
  end
end