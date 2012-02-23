require 'logger'

module Metriks::Reporter
  class Logger
    def initialize(options = {})
      @registry  = options[:registry]  || Metriks::Registry.default
      @logger    = options[:logger]    || ::Logger.new(STDOUT)
      @log_level = options[:log_level] || ::Logger::INFO
      @prefix    = options[:prefix]    || 'metriks:'
      @interval  = options[:interval]  || 60
      @on_errror = options[:on_error]  || proc { |ex| }
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

    def write
      @registry.each do |name, metric|
        case metric
        when Metriks::Meter
          log_metric name, 'meter', metric, [
            :count, :one_minute_rate, :five_minute_rate,
            :fifteen_minute_rate, :mean_rate
          ]
        when Metriks::Counter
          log_metric name, 'counter', metric, [
            :count
          ]
        when Metriks::UtilizationTimer
          log_metric name, 'utilization_timer', metric, [
            :count, :one_minute_rate, :five_minute_rate,
            :fifteen_minute_rate, :mean_rate,
            :min, :max, :mean, :stddev,
            :one_minute_utilization, :five_minute_utilization,
            :fifteen_minute_utilization, :mean_utilization,
          ]
        when Metriks::Timer
          log_metric name, 'timer', metric, [
            :count, :one_minute_rate, :five_minute_rate,
            :fifteen_minute_rate, :mean_rate,
            :min, :max, :mean, :stddev
          ]
        end
      end
    end

    def extract_from_metric(metric, *keys)
      keys.flatten.collect do |key|
        [ { key => metric.send(key) } ]
      end
    end

    def log_metric(name, type, metric, *keys)
      message = []

      message << @prefix if @prefix
      message << { :time => Time.now.to_i }

      message << { :name => name }
      message << { :type => type }
      message += extract_from_metric(metric, keys)

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