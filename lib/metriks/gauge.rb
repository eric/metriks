require 'atomic'

module Metriks
  class Gauge
    # Public: Initialize a new Gauge.
    def initialize
      @gauge = Atomic.new(0)
      @callback = Atomic.new(proc {})
    end

    # Public: Set a new value.
    #
    # val - The new value.
    #
    # Returns nothing.
    def set(val)
      @gauge.value = val
    end

    # Public: Set a callback.
    #
    # callable - The callback to execute when `#value` is called.
    #            Takes an object that responds to `#call` as first parameter
    #            or a block.
    #
    # Returns nothing.
    def callback(callable = nil, &block)
      callable ||= block
      @callback.value = callable
    end

    # Public: The current value.
    #
    # Returns the gauge value.
    def value
      @callback.value.call || @gauge.value
    end
  end
end
