require 'logger'
require 'metriks/time_tracker'

module Metriks::Reporter
  class Logger
    attr_accessor :prefix, :log_level, :logger

    def initialize(options = {})
      @logger    = options[:logger]    || ::Logger.new(STDOUT)
      @log_level = options[:log_level] || ::Logger::INFO
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
        log_metrics name, metric.export_values
      end
    end

    def log_metrics(name, values)
      message = []

      message << @prefix if @prefix
      message << { :time => Time.now.to_i }

      message << { :name => name }
      message << { :type => type }
      message.merge!(values)

      @logger.add(@log_level, format_message(message))
    end

    def format_message(args)
      args.map do |arg|
        case arg
        when Hash then arg.map { |name, value| "#{name}=#{format_message([value])}" }
        when Array then format_message(arg)
        else arg
        end
      end.join(' ')
    end
  end
end
