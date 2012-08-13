require 'metriks/timer'

module Metriks
  class UtilizationTimer < Metriks::Timer
    def initialize
      super
      @duration_meter = Metriks::Meter.new
    end

    def type
      'utilization_timer'
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

    def each
      report_snapshot = snapshot
      yield 'count',                      count
      yield 'one_minute_rate',            one_minute_rate
      yield 'five_minute_rate',           five_minute_rate
      yield 'fifteen_minute_rate',        fifteen_minute_rate
      yield 'mean_rate',                  mean_rate
      yield 'min',                        min
      yield 'max',                        max
      yield 'mean',                       mean
      yield 'stddev',                     stddev
      yield 'one_minute_utilization',     one_minute_utilization
      yield 'five_minute_utilization',    five_minute_utilization
      yield 'fifteen_minute_utilization', fifteen_minute_utilization
      yield 'mean_utilization',           mean_utilization
      yield 'median',                     report_snapshot.median
      yield '95th_percentile',            report_snapshot.get_95th_percentile
    end
  end
end
