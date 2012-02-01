require 'atomic'

class Metriks::Counter
  def initialize
    @counter = Atomic.new(0)
  end

  def clear
    @counter.value = 0
  end

  def increment(incr = 1)
    @counter.update { |v| v + incr }
  end

  def count
    @counter.value
  end
end