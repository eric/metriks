require 'metriks/reporter'
require 'metriks/registry'
require 'metriks/time_tracker'
require 'riemann/client'

class Metriks::Reporter
  class Riemann < Metriks::Reporter
    attr_accessor :client

    def initialize(options = {})
      @client = ::Riemann::Client.new :host => options[:host],
                                      :port => options[:port]

      interval = options[:interval] || 60
      @default_event = options[:default_event] || {}
      @default_event[:ttl] ||= interval * 1.5

      super options
    end

    def flush
      # Is this supposed to take interval into account? --aphyr
      if !@last_write || @last_write.min != Time.now.min
        write
      end
    end

    def write
      @last_write = Time.now
      @registry.each do |name, metric|
        metric.each do |key, value|
          @client << @default_event.merge(:service => "#{ name } #{ key }",
                                          :metric  => value,
                                          :tags    => [metric.type])
        end
      end
    end
  end
end
