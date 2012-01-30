require 'atomic'

class MetriksClient::Counter
  def initialize
    @value = Atomic.new(0)
  end

  def increment(incr = 1)
    @value.update { |v| v + incr }
  end

  def count
    @value.value
  end

  def reset
    @value.swap(0)
  end
end