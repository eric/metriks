require 'logger'
require 'metriks/time_tracker'

module Metriks::Reporter
  class Logger
    attr_accessor :prefix, :log_level, :logger, :percentile_methods

    def initialize(options = {})
      @logger    = options[:logger]    || ::Logger.new(STDOUT)
      @log_level = options[:log_level] || ::Logger::INFO
      @prefix    = options[:prefix]    || 'metriks:'

      @registry     = options[:registry] || Metriks::Registry.default
      @time_tracker = Metriks::TimeTracker.new(options[:interval] || 60)
      @on_error     = options[:on_error] || proc { |ex| }

      @percentile_methods = Metriks::Snapshot.methods_for_percentiles(options.fetch(:percentiles, :p95))
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
        case metric
        when Metriks::Meter
          log_metric name, 'meter', metric, metric.class.reportable_metrics
        when Metriks::Counter
          log_metric name, 'counter', metric, metric.class.reportable_metrics
        when Metriks::Gauge
          log_metric name, 'gauge', metric, metric.class.reportable_metrics
        when Metriks::UtilizationTimer
          log_metric name, 'utilization_timer', metric, metric.class.reportable_metrics,
            metric.class.reportable_snapshot_metrics(:percentiles => percentile_methods)
        when Metriks::Timer
          log_metric name, 'timer', metric, metric.class.reportable_metrics,
            metric.class.reportable_snapshot_metrics(:percentiles => percentile_methods)
        when Metriks::Histogram
          log_metric name, 'histogram', metric, metric.class.reportable_metrics,
            metric.class.reportable_snapshot_metrics(:percentiles => percentile_methods)
        end
      end
    end

    def extract_from_metric(metric, *keys)
      keys.flatten.collect do |key|
        name = key.to_s.gsub(/^get_/, '')
        [ { name => metric.send(key) } ]
      end
    end

    def log_metric(name, type, metric, keys, snapshot_keys = [])
      message = []

      message << @prefix if @prefix
      message << { :time => Time.now.to_i }

      message << { :name => name }
      message << { :type => type }
      message += extract_from_metric(metric, keys)

      unless snapshot_keys.empty?
        snapshot = metric.snapshot
        message += extract_from_metric(snapshot, snapshot_keys)
      end

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
