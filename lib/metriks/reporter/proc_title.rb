require 'metriks/registry'
require 'metriks/time_tracker'

module Metriks::Reporter
  class ProcTitle
    def initialize(options = {})
      @rounding = options[:rounding] || 1
      @prefix = options[:prefix] || $0

      @time_tracker = Metriks::TimeTracker.new(options[:interval] || 60)
      @on_error     = options[:on_error] || proc { |ex| }

      @metrics = []
    end

    def add(name, suffix = nil, &block)
      @metrics << [ name, suffix, block ]
    end

    def empty?
      @metrics.empty?
    end

    def start
      @thread ||= Thread.new do
        loop do
          begin
            write
          rescue Exception => ex
            @on_error[ex] rescue nil
          end

          @time_tracker.sleep
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
      return if empty?
      $0 = "#{ @prefix } #{ title }"
    end

    protected

    def title
      @metrics.map do |name, suffix, block|
        value = rounded_value block.call
        suffix = "/#{ suffix }" if suffix && suffix != '%'
        "#{ name }: #{ value }#{ suffix }"
      end.join(' ')
    end

    def rounded_value(value)
      return value unless value.is_a?(Float)
      "%.#{ @rounding }f" % value
    end
  end
end
