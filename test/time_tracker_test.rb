require 'test/unit'
require 'mocha'
require 'metriks/time_tracker'

class TimeTrackerTest < Test::Unit::TestCase
  def test_set_interval
    tracker = Metriks::TimeTracker.new 42
    assert_equal 42, tracker.interval
  end

  def test_sleep_until_next_interval
    tracker = Metriks::TimeTracker.new 10
    Time.stubs(:now).returns(Time.new(2012, 4, 1, 0, 0, 2))
    Kernel.expects(:sleep).with(8.0)
    tracker.sleep
  end

  def test_time_until_next_interval
    tracker = Metriks::TimeTracker.new 10
    Time.stubs(:now).returns(Time.new(2012, 4, 1, 0, 0, 2))
    assert_equal 8, tracker.time_until_next_interval
  end

  def test_now_floored_returns_current_interval
    tracker = Metriks::TimeTracker.new 10
    Time.stubs(:now).returns(Time.new(2012, 4, 1, 0, 0, 2))
    assert_equal Time.new(2012, 4, 1).to_f, tracker.now_floored
  end
end
