require 'atomic'

module Metriks
  class Gauge
    # Public: Initialize a new Gauge.
    def initialize
      @gauge = Atomic.new(0)
    end

    # Public: Set a new value.
    #
    # val - The new value.
    #
    # Returns nothing.
    def set(val)
      @gauge.value = val
    end

    # Public: The current value.
    #
    # Returns the gauge value.
    def value
      @gauge.value
    end
  end
end
