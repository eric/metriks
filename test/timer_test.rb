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
    3.times do
      @timer.time do
        sleep 0.1
      end
    end

    assert_in_delta 0.1, @timer.mean, 0.01
    assert_in_delta 0.1, @timer.snapshot.median, 0.01
  end

  def test_timer_without_block
    t = @timer.time
    sleep 0.1
    t.stop

    assert_in_delta 0.1, @timer.mean, 0.01
  end

  def test_exportable_metrics
    2.times do
      @timer.time do
        sleep 0.1
      end
    end

    values = @timer.export_values

    assert_equal 2, values[:count]

    expected = {
      :min    => [0.1, 0.1],
      :max    => [0.1, 0.1],
      :mean   => [0.1, 0.1],
      :stddev => [1,   1],
      :one_minute_rate => [0, 0],
      :five_minute_rate => [0, 0],
      :fifteen_minute_rate => [0, 0],
      :median => [0.1, 0.1],
      :"95th_percentile" => [0.1, 0.1]
    }

    expected.each_pair do |metric, expectation|
      target,delta = expectation

      assert_in_delta target, values[metric], delta, "#{metric}"
    end
  end
end
