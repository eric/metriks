require 'metriks/registry'
require 'metriks/time_tracker'

module Metriks
  class Reporter
    attr_reader :registry

    def initialize(options = {})
      @time_tracker = Metriks::TimeTracker.new(options[:interval] || 60)
      @registry     = options[:registry] || Metriks::Registry.default
      @on_error     = options[:on_error] || proc { |ex| }
    end

    def write
      # Override in subclass
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
  end
end
