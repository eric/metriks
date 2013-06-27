require 'atomic'
require 'hitimes'

require 'metriks/meter'
require 'metriks/histogram'

module Metriks
  class Timer
    class Context
      def initialize(timer)
        @timer    = timer
        @interval = Hitimes::Interval.now
      end

      def restart
        @interval = Hitimes::Interval.now
      end

      def stop
        @interval.stop
        @timer.update(@interval.duration)
      end
    end

    def initialize(histogram = Metriks::Histogram.new_exponentially_decaying)
      @meter     = Metriks::Meter.new
      @histogram = histogram
    end

    def clear
      @meter.clear
      @histogram.clear
    end

    def update(duration)
      if duration >= 0
        @meter.mark
        @histogram.update(duration)
      end
    end

    def time(callable = nil, &block)
      callable ||= block
      context = Context.new(self)

      if callable.nil?
        return context
      end

      begin
        return callable.call
      ensure
        context.stop
      end
    end

    def snapshot
      @histogram.snapshot
    end

    def count
      @histogram.count
    end

    def one_minute_rate
      @meter.one_minute_rate
    end

    def five_minute_rate
      @meter.five_minute_rate
    end

    def fifteen_minute_rate
      @meter.fifteen_minute_rate
    end

    def mean_rate
      @meter.mean_rate
    end

    def min
      @histogram.min
    end

    def max
      @histogram.max
    end

    def mean
      @histogram.mean
    end

    def stddev
      @histogram.stddev
    end

    def stop
      @meter.stop
    end

    # Public: An array of methods to be used for reporting metrics through a
    # reporter.
    #
    # Returns an array of symbols of methods that can be called.
    def self.reportable_metrics
      [
        :count, :one_minute_rate, :five_minute_rate, :fifteen_minute_rate,
        :mean_rate, :min, :max, :mean, :stddev
      ]
    end

    # Public: An array of methods to be used for reporting snapshot metrics
    # through a reporter.
    #
    # options[:percentiles] - An array of percentiles methods to include. These
    # must be valid methods on Metriks::Snapshot.
    #
    # Returns an array of symbols of methods that can be called.
    def self.reportable_snapshot_metrics(options = {})
      [:median] + options.fetch(:percentiles, [])
    end
  end
end