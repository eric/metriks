module Metriks
  module Reporter
    class FlatteningRegistryEnumerator
      def initialize(registry)
        @registry = registry
      end
      
      def each(&block)
        @registry.each do |name, metric|
          case metric
          when Metriks::Meter
            block.call("#{name}.count", metric.count)
            block.call("#{name}.one_minute_rate", metric.one_minute_rate)
            block.call("#{name}.five_minute_rate", metric.five_minute_rate)
            block.call("#{name}.fifteen_minute_rate", metric.fifteen_minute_rate)
            block.call("#{name}.mean_rate", metric.mean_rate)
          when Metriks::Counter
            block.call("#{name}.count", metric.count)
          when Metriks::Gauge
            block.call("#{name}.value", metric.value)
          when Metriks::UtilizationTimer
            block.call("#{name}.count", metric.count)
            block.call("#{name}.one_minute_rate", metric.one_minute_rate)
            block.call("#{name}.five_minute_rate", metric.five_minute_rate)
            block.call("#{name}.fifteen_minute_rate", metric.fifteen_minute_rate)
            block.call("#{name}.mean_rate", metric.mean_rate)

            block.call("#{name}.min", metric.min)
            block.call("#{name}.max", metric.max)
            block.call("#{name}.median", metric.median)
            block.call("#{name}.stddev", metric.stddev)

            block.call("#{name}.one_minute_utilization", metric.one_minute_utilization)
            block.call("#{name}.five_minute_utilization", metric.five_minute_utilization)
            block.call("#{name}.fifteen_minute_utilization", metric.fifteen_minute_utilization)
            
            snapshot = metric.snapshot

            block.call("#{name}.median", snapshot.median)
            block.call("#{name}.75th_percentile", snapshot.get_75th_percentile)
            block.call("#{name}.95th_percentile", snapshot.get_95th_percentile)
            block.call("#{name}.98th_percentile", snapshot.get_98th_percentile)
            block.call("#{name}.99th_percentile", snapshot.get_99th_percentile)
            block.call("#{name}.999th_percentile", snapshot.get_999th_percentile)
          when Metriks::Timer
            block.call("#{name}.count", metric.count)
            block.call("#{name}.one_minute_rate", metric.one_minute_rate)
            block.call("#{name}.five_minute_rate", metric.five_minute_rate)
            block.call("#{name}.fifteen_minute_rate", metric.fifteen_minute_rate)
            block.call("#{name}.mean_rate", metric.mean_rate)

            block.call("#{name}.min", metric.min)
            block.call("#{name}.max", metric.max)
            block.call("#{name}.median", metric.median)
            block.call("#{name}.stddev", metric.stddev)
            
            snapshot = metric.snapshot

            block.call("#{name}.median", snapshot.median)
            block.call("#{name}.75th_percentile", snapshot.get_75th_percentile)
            block.call("#{name}.95th_percentile", snapshot.get_95th_percentile)
            block.call("#{name}.98th_percentile", snapshot.get_98th_percentile)
            block.call("#{name}.99th_percentile", snapshot.get_99th_percentile)
            block.call("#{name}.999th_percentile", snapshot.get_999th_percentile)
          when Metriks::Histogram
            block.call("#{name}.count", metric.count)
            block.call("#{name}.min", metric.min)
            block.call("#{name}.max", metric.max)
            block.call("#{name}.median", metric.median)
            block.call("#{name}.stddev", metric.stddev)
            
            snapshot = metric.snapshot

            block.call("#{name}.median", snapshot.median)
            block.call("#{name}.75th_percentile", snapshot.get_75th_percentile)
            block.call("#{name}.95th_percentile", snapshot.get_95th_percentile)
            block.call("#{name}.98th_percentile", snapshot.get_98th_percentile)
            block.call("#{name}.99th_percentile", snapshot.get_99th_percentile)
            block.call("#{name}.999th_percentile", snapshot.get_999th_percentile)
          end
        end
      end
    end
  end
end