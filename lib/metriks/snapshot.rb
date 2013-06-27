module Metriks
  class Snapshot
    VALID_PERCENTILES = [:p75, :p95, :p98, :p99, :p999]

    MEDIAN_Q = 0.5
    P75_Q = 0.75
    P95_Q = 0.95
    P98_Q = 0.98
    P99_Q = 0.99
    P999_Q = 0.999

    attr_reader :values

    def initialize(values)
      @values = values.sort
    end

    def value(quantile)
      raise ArgumentError, "quantile must be between 0.0 and 1.0" if quantile < 0.0 || quantile > 1.0

      return 0.0 if @values.empty?

      pos = quantile * (@values.length + 1)

      return @values.first if pos < 1
      return @values.last if pos >= @values.length

      lower = @values[pos.to_i - 1]
      upper = @values[pos.to_i]
      lower + (pos - pos.floor) * (upper - lower)
    end

    def size
      @values.length
    end

    def median
      value(MEDIAN_Q)
    end

    def get_75th_percentile
      value(P75_Q)
    end

    def get_95th_percentile
      value(P95_Q)
    end

    def get_98th_percentile
      value(P98_Q)
    end

    def get_99th_percentile
      value(P99_Q)
    end

    def get_999th_percentile
      value(P999_Q)
    end

    def self.valid_percentile?(percentile)
      VALID_PERCENTILES.include?(percentile)
    end

    # Public: Convert symbol percentiles into an array of methods to be called
    # on a Snapshot object.
    #
    # percentiles - A symbol, or list of symbols, that represents the percentile
    # that a method is needed for.
    #
    # Example:
    #   Metriks::Snapshot.methods_for_percentiles(:p95, :p99)
    #   # => [:get_95th_percentile, :get_99th_percentile]
    #
    # Returns an array of symbols
    def self.methods_for_percentiles(*percentiles)
      methods = percentiles.flatten.collect do |percentile|
        next unless valid_percentile?(percentile)
        :"get_#{percentile.to_s.gsub('p', '')}th_percentile"
      end
      methods.compact
    end
  end
end
