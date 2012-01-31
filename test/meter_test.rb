require 'test_helper'

require 'metriks/meter'

class MeterTest < Test::Unit::TestCase
  def setup
    @meter = Metriks::Meter.new
  end
  
  def teardown
    @meter.stop
  end
end