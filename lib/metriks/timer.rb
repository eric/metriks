require 'atomic'

class Metriks::Timer
  def initialize
    @meter = Meter.new
    @count = Atomic.new(0)
  end

  def update(duration)
    if duration >= 0
      @meter.mark
    end
  end

  def time(callable = nil, &block)
    callable ||= block
    start_time = Time.now

    begin
      return callable.call
    ensure
      update(Time.now - start_time)
    end
  end

  def count
    @meter.count
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

  def stop
    @meter.stop
  end
end