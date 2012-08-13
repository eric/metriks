module Metriks::Reporter
  class Riemann
    require 'riemann/client'

    attr_accessor :client
    def initialize(options = {})
      @client = ::Riemann::Client.new(
        :host => options[:host],
        :port => options[:port]
      )
      @registry = options[:registry] || Metrics::Registry.default
      @interval = options[:interval] || 60
      @on_error = options[:on_error] || proc { |ex| }
      
      @default_event = options[:default_event] || {}
      @default_event[:ttl] ||= @interval * 1.5
    end

    def start
      @thread ||= Thread.new do
        loop do
          sleep @interval
          
          Thread.new do
            begin
              write
            rescue Exception => ex
              @on_error[ex] rescue nil
            end
          end
        end
      end
    end

    def stop
      @thread.kill if @thread
      @thread = nil
    end

    def restart
      stop
      start
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
          @client << @default_event.merge(
            :service => "#{name} #{key}",
            :metric => value,
            :tags => [metric.type]
          )
        end
      end
    end
  end
end
