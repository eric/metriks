require 'metriks/timer'

module Metriks
  class UtilizationTimer < Metriks::Timer
    def initialize
      super
      @duration_meter = Metriks::Meter.new
    end

    def clear
      super
      @duration_meter.clear
    end

    def update(duration)
      super
      if duration >= 0
        @duration_meter.mark(duration)
      end
    end

    def one_minute_utilization
      @duration_meter.one_minute_rate
    end

    def five_minute_utilization
      @duration_meter.five_minute_rate
    end

    def fifteen_minute_utilization
      @duration_meter.fifteen_minute_rate
    end

    def mean_utilization
      @duration_meter.mean_rate
    end

    def stop
      super
      @duration_meter.stop
    end

    # Public: An array of methods to be used for reporting metrics through a
    # reporter.
    #
    # Returns an array of symbols of methods that can be called.
    def self.reportable_metrics
      [
        :count, :one_minute_rate, :five_minute_rate, :fifteen_minute_rate,
        :mean_rate, :min, :max, :mean, :stddev, :one_minute_utilization,
        :five_minute_utilization, :fifteen_minute_utilization,
        :mean_utilization
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