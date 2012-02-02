require 'test_helper'

require 'metriks/histogram'

class HistogramTest < Test::Unit::TestCase
  def setup
    @histogram = Metriks::Histogram.new(Metriks::UniformSample.new(Metriks::Histogram::DEFAULT_SAMPLE_SIZE))
  end

  def test_min
    @histogram.update(5)
    @histogram.update(10)

    assert_equal 5, @histogram.min
  end

  def test_max
    @histogram.update(5)
    @histogram.update(10)

    assert_equal 10, @histogram.max
  end

  def test_mean
    @histogram.update(5)
    @histogram.update(10)

    assert_equal 7, @histogram.mean
  end

  def test_2000
    2000.times do |idx|
      @histogram.update(idx)
    end

    assert_equal 1999, @histogram.max
  end
end