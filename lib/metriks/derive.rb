require 'atomic'

require 'metriks/meter'

module Metriks
  class Derive < Metriks::Meter
    def mark(val = 1)
      @last ||= Atomic.new(val)
      last = @last.swap(val)
      super(last > val ? val : val - last)
    end
  end
end
