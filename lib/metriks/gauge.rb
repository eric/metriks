require 'atomic'

module Metriks
  class Gauge
    # Public: Initialize a new Gauge.
    def initialize(callable = nil, &block)
      @gauge = Atomic.new(nil)
      @callback = callable || block
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
      @callback ? @callback.call : @gauge.value
    end

    # Public: An array of methods to be used for reporting metrics through a
    # reporter.
    #
    # Returns an array of symbols.
    def self.reportable_metrics
      [:value]
    end

    # Public: An array of methods to be used for reporting snapshot metrics
    # through a reporter.
    #
    # options - No supported options.
    #
    # Returns an array of symbols.
    def self.reportable_snapshot_metrics(options = {})
      []
    end
  end
end
