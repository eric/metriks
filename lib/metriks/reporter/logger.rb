require 'logger'
require 'metriks/registry'
require 'metriks/time_tracker'

module Metriks::Reporter
  class Logger
    attr_accessor :prefix, :log_level, :logger

    def initialize(options = {})
      @log_level = options[:log_level] || ::Logger::INFO
      @logger    = options[:logger]    || ::Logger.new(STDOUT)
      @prefix    = options[:prefix]    || 'metriks:'

      @registry     = options[:registry] || Metriks::Registry.default
      @time_tracker = Metriks::TimeTracker.new(options[:interval] || 60)
      @on_error     = options[:on_error] || proc { |ex| }
    end

    def start
      @thread ||= Thread.new do
        loop do
          @time_tracker.sleep

          begin
            write
          rescue Exception => ex
            @on_error[ex] rescue nil
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
      if !@last_write || @last_write.min != Time.now.min
        write
      end
    end

    def write
      @last_write = Time.now
      @registry.each do |name, metric|
        log_metric name, metric, @last_write.to_i
      end
    end

    def log_metric(name, metric, time)
      message = []
      message << @prefix if @prefix
      message << format_data('time', time)
      message << format_data('name', name)
      message << format_data('type', metric.type)
      metric.each do |name, value|
        message << format_data(name, value)
      end

      @logger.add(@log_level, message.join(' '))
    end

    def format_data(name, value)
      [ name, value ].join('=')
    end
  end
end
