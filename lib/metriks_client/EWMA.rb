class MetriksClient::EWMA
  INTERVAL = 5
  SECONDS_PER_MINUTE = 60.0

  ONE_MINUTE      = 1
  FIVE_MINUTES    = 5
  FIFTEEN_MINUTES = 15

  M1_ALPHA  = 1 - Math.exp(-INTERVAL / SECONDS_PER_MINUTE / ONE_MINUTE)
  M5_ALPHA  = 1 - Math.exp(-INTERVAL / SECONDS_PER_MINUTE / FIVE_MINUTES)
  M15_ALPHA = 1 - Math.exp(-INTERVAL / SECONDS_PER_MINUTE / FIFTEEN_MINUTES)

  def initialize(atomic, interval)
    @alpha    = atomic
    @interval = interval

    @initialized = false
    @rate        = Atomic.new(0.0)
    @uncounted   = Atomic.new(0)
  end

  def update(value)
    @uncounted.update { |v| v + value }
  end

  def tick
    count = @uncounted.swap(0)
    instant_rate = count / @interval

    if @initialized
      @rate.update { |v| v + (@alpha * (instant_rate - rate )) }
    else
      @rate.value = instant_rate
      @initialized
    end
  end

  def rate

  end
end