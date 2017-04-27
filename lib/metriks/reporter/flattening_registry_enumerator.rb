module Metriks
  module Reporter
    class FlatteningRegistryEnumerator
      include Enumerable

      def initialize(registry, options = {})
        @registry = registry
        unless options[:current_rate]
          @last = Hash.new { |h,k| h[k] = 0 }
        end

        if options[:percentiles]
          @percentiles = options[:percentiles]
        else
          @percentiles = [ 0.75, 0.95, 0.98, 0.99, 0.999 ]
        end
      end

      def each(&block)
        @registry.each do |name, metric|
          for_metric(name, metric, &block)
        end
      end

      def for_metric(name, metric, &block)
        name = name.to_s.gsub(/ +/, '_')

        case metric
        when Metriks::Meter
          if @last
            count = metric.count
            block.call(name, count - @last[name], metric.class)
            @last[name] = count
          else
            block.call("#{name}.count", metric.count, metric.class)
            block.call("#{name}.one_minute_rate", metric.one_minute_rate, metric.class)
            block.call("#{name}.five_minute_rate", metric.five_minute_rate, metric.class)
            block.call("#{name}.fifteen_minute_rate", metric.fifteen_minute_rate, metric.class)
            block.call("#{name}.mean_rate", metric.mean_rate, metric.class)
          end

        when Metriks::Counter
          block.call("#{name}", metric.count, metric.class)
        when Metriks::Gauge
          block.call("#{name}", metric.value, metric.class)
        when Metriks::UtilizationTimer
          if @last
            count = metric.count
            block.call(name, count - @last[name], metric.class)
            @last[name] = count
          else
            block.call("#{name}.one_minute_rate", metric.one_minute_rate, metric.class)
            block.call("#{name}.five_minute_rate", metric.five_minute_rate, metric.class)
            block.call("#{name}.fifteen_minute_rate", metric.fifteen_minute_rate, metric.class)
          end

          block.call("#{name}.min", metric.min, metric.class)
          block.call("#{name}.max", metric.max, metric.class)
          block.call("#{name}.stddev", metric.stddev, metric.class)

          block.call("#{name}.one_minute_utilization", metric.one_minute_utilization, metric.class)
          block.call("#{name}.five_minute_utilization", metric.five_minute_utilization, metric.class)
          block.call("#{name}.fifteen_minute_utilization", metric.fifteen_minute_utilization, metric.class)

          snapshot = metric.snapshot

          block.call("#{name}.median", snapshot.median, metric.class)

          for_percentiles(name, metric, snapshot, &block)

        when Metriks::Timer
          if @last
            count = metric.count
            block.call(name, count - @last[name], metric.class)
            @last["#{name}.count"] = count
          else
            block.call("#{name}.count", metric.count, metric.class)
            block.call("#{name}.one_minute_rate", metric.one_minute_rate, metric.class)
            block.call("#{name}.five_minute_rate", metric.five_minute_rate, metric.class)
            block.call("#{name}.fifteen_minute_rate", metric.fifteen_minute_rate, metric.class)
            block.call("#{name}.mean_rate", metric.mean_rate, metric.class)
          end

          block.call("#{name}.min", metric.min, metric.class)
          block.call("#{name}.max", metric.max, metric.class)
          block.call("#{name}.stddev", metric.stddev, metric.class)

          snapshot = metric.snapshot

          block.call("#{name}.median", snapshot.median, metric.class)

          for_percentiles(name, metric, snapshot, &block)

        when Metriks::Histogram
          block.call("#{name}.count", metric.count, metric.class)
          block.call("#{name}.min", metric.min, metric.class)
          block.call("#{name}.max", metric.max, metric.class)
          block.call("#{name}.stddev", metric.stddev, metric.class)

          snapshot = metric.snapshot

          block.call("#{name}.median", snapshot.median, metric.class)

          for_percentiles(name, metric, snapshot, &block)
        end
      end


      def for_percentiles(name, metric, snapshot, &block)
        @percentiles.each do |percentile|
          percentile_name = (percentile * 100).to_f.to_s.gsub(/0+$/, '').gsub('.', '')
          block.call("#{name}.#{percentile_name}th_percentile", snapshot.value(percentile), metric.class)
        end
      end
    end
  end
end