require 'test_helper'

require 'metriks/counter'

class CounterTest < Test::Unit::TestCase
  def setup
    @counter = Metriks::Counter.new
  end

  def test_increment
    @counter.increment

    assert_equal 1, @counter.count
  end

  def test_increment_by_more
    @counter.increment 10

    assert_equal 10, @counter.count
  end
end