require 'logger'
require 'metriks/reporter'
require 'metriks/registry'
require 'metriks/time_tracker'

class Metriks::Reporter
  class Logger < Metriks::Reporter
    attr_accessor :prefix, :log_level, :logger

    def initialize(options = {})
      @log_level = options[:log_level] || ::Logger::INFO
      @logger    = options[:logger]    || ::Logger.new(STDOUT)
      @prefix    = options[:prefix]    || 'metriks:'

      super options
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
