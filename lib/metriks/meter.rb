require 'atomic'

require 'metriks/ewma'

module Metriks
  class Meter
    def initialize(averager_klass = Metriks::EWMA)
      @count = Atomic.new(0)
      @start_time = Time.now

      @m1_rate  = averager_klass.new_m1
      @m5_rate  = averager_klass.new_m5
      @m15_rate = averager_klass.new_m15

      @thread = Thread.new do
        loop do
          sleep averager_klass::INTERVAL
          tick
        end
      end
    end

    def clear
      @count.value = 0
      @start_time = Time.now
      @m1_rate.clear
      @m5_rate.clear
      @m15_rate.clear
    end

    def tick
      @m1_rate.tick
      @m5_rate.tick
      @m15_rate.tick
    end

    def mark(val = 1)
      @count.update { |v| v + val }
      @m1_rate.update(val)
      @m5_rate.update(val)
      @m15_rate.update(val)
    end

    def count
      @count.value
    end

    def one_minute_rate
      @m1_rate.rate
    end

    def five_minute_rate
      @m5_rate.rate
    end

    def fifteen_minute_rate
      @m15_rate.rate
    end

    def mean_rate
      if count == 0
        return 0.0
      else
        elapsed = Time.now - @start_time
        count / elapsed
      end
    end

    def stop
      @thread.kill
    end

    def each(&block)
      yield 'count',               count
      yield 'one_minute_rate',     one_minute_rate
      yield 'five_minute_rate',    five_minute_rate
      yield 'fifteen_minute_rate', fifteen_minute_rate
      yield 'mean_rate',           mean_rate
    end
  end
end
