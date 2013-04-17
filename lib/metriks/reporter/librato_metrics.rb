require 'metriks/time_tracker'
require 'librato/metrics'

module Metriks::Reporter
  class LibratoMetrics
    attr_accessor :prefix, :source

    def initialize(email, token, options = {})
      @email = email
      @token = token

      @client = Librato::Metrics::Client.new
      @client.authenticate(@email, @token)

      @prefix = options[:prefix]
      @source = options[:source]

      @registry  = options[:registry] || Metriks::Registry.default
      @time_tracker = Metriks::TimeTracker.new(options[:interval] || 60)
      @on_error  = options[:on_error] || proc { |ex| }
    end

    def start
      @thread ||= Thread.new do
        loop do
          @time_tracker.sleep

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

    def write
      time  = @time_tracker.now_floored
      queue = @client.new_queue

      Metriks::Reporter::CounterDerivative.new(@registry).each do |name, value|
        if prefix
          name = "#{prefix}.#{name}"
        end

        queue.add name => {
          :source       => @source,
          :value        => value,
          :measure_time => time,
          :type         => 'gauge'
        }
      end

      queue.submit
    end
  end
end
