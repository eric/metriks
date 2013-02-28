require 'test_helper'
require 'metriks/exportable'

class ExportableTest < Test::Unit::TestCase

  def test_export_values_raises_error_if_no_exportables_defined
    metric = Class.new do
      include Metriks::Exportable
    end

    assert_raise NotImplementedError do
      metric.new.export_values
    end
  end

  def test_export_values_returns_metric_values
    metric = Class.new do
      include Metriks::Exportable

      def exportable_metrics
        [:count]
      end

      def count
        42
      end
    end

    assert_equal({:count => 42}, metric.new.export_values)
  end
end
