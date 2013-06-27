require 'test_helper'
require 'metriks/snapshot'

class MetriksSnapshotTest < Test::Unit::TestCase
  def test_skips_invalid_percentiles
    methods = Metriks::Snapshot.methods_for_percentiles(:p999, :invalid_percentile)
    assert_equal [:get_999th_percentile], methods
  end

  def test_multiple_percentiles
    methods = Metriks::Snapshot.methods_for_percentiles(:p999, :p95)
    assert_equal [:get_999th_percentile, :get_95th_percentile], methods
  end
end
