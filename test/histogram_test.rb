require 'test_helper'

require 'metriks/histogram'

class HistogramTest < Test::Unit::TestCase
  def setup
    @histogram = Metriks::Histogram.new(Metriks::UniformSample.new(Metriks::Histogram::DEFAULT_SAMPLE_SIZE))
  end
end