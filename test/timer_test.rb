require 'test_helper'

require 'metriks/timer'

class TimerTest < Test::Unit::TestCase
  def setup
    @timer = Metriks::Timer.new
  end
  
  def teardown
    @timer.stop
  end
end