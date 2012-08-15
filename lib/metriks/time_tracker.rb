module Metriks
  class TimeTracker
    attr_reader :interval

    def initialize(interval)
      @interval = interval
    end

    def sleep
      Kernel.sleep time_until_next_interval
    end

    def time_until_next_interval
      interval - (Time.now.to_f % interval)
    end

    def now_floored
      Time.now.to_f + time_until_next_interval - interval
    end
  end
end
