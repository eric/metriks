
module Metriks
  module Exportable

    # Public: Get the type of this metric
    #
    # This key is used by certain reporters such as logger
    def metric_type
      self.class.name.split('::').last.gsub(/(.)([A-Z])/, '\1_\2').downcase
    end

    # Public: Export all of the Metric's computed values as a hash
    def export_values
      values = capture_metrics(self, exportable_metrics)

      if respond_to? :snapshot
        values = values.merge(capture_metrics(snapshot, exportable_snapshots))
      end

      values
    end

    private
    # Private: Array of metrics that this metric object can calculate
    #
    # Returns: Array
    def exportable_metrics
      raise NotImplementedError, "Metrics must declare a set of exportable values"
    end

    # Private: Array of metrics that can be calculated from a snapshot
    # of the data
    #
    # Returns: Array
    def exportable_snapshots
      []
    end

    def capture_metrics(source, metric)
      Array(metric).inject({}) do |values,key|
        name = String(key).gsub(/^get_/, '').to_sym

        values.tap do |h|
          h[name] = source.send(key)
        end
      end
    end
  end
end
