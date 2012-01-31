require 'atomic'

require 'metriks/meter'
require 'metriks/histogram'

class Metriks::Timer
  def initialize
    @meter     = Metriks::Meter.new
    @histogram = Metriks::Histogram.new_uniform
  end

  def update(duration)
    if duration >= 0
      @meter.mark
      @histogram.update(duration)
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

  def stop
    @meter.stop
  end
end