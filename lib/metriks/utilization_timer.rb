require 'metriks/timer'

module Metriks
  class UtilizationTimer < Metriks::Timer
    def update(duration)
      if duration >= 0
        @meter.mark(duration)
        @histogram.update(duration)
      end
    end

    def one_minute_utilization
      one_minute_rate
    end

    def five_minute_utilization
      five_minute_rate
    end

    def fifteen_minute_utilization
      fifteen_minute_rate
    end
  end
end