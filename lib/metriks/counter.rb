require 'atomic'

class Metriks::Counter
  def initialize
    @count = Atomic.new(0)
  end

  def clear
    @count.value = 0
  end

  def increment(incr = 1)
    @count.update { |v| v + incr }
  end

  def decrement(decr = 1)
    @count.update { |v| v - decr }
  end

  def count
    @count.value
  end
end