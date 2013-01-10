require 'metriks/time_tracker'

gem 'instrumental_agent'
require 'instrumental_agent'

module Metriks::Reporter

  # Reports metrics to Instrumental (http://instrumentalapp.com/)
  class Instrumental
    attr_accessor :prefix, :source, :agent

    # You MUST provide either :api_token or :agent as an argument to this method.
    #
    # options:
    # :api_token:: Your Instrumental API token
    # :agent:: A specific instance of the Instrumental Agent to use with this reporter
    # :prefix:: A string prefix to prepend to all your metrics
    # :registry:: The Metriks registry that will be providing your metrics
    # :interval:: How often to report metrics to Instrumental
    # :on_error:: A callable object to be executed when an error occurs. This WILL be called
    #             from a separate thread, you must ensure that your provided code will be 
    #             thread safe.

    def initialize(options = {})
      raise "You must provide either :agent or :api_token as an option" unless options[:agent] || options[:api_token]
      @agent = options[:agent] || ::Instrumental::Agent.new(options[:api_token])

      @prefix = options[:prefix]

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
      @registry.each do |name, metric|
        case metric
        when Metriks::Meter
          send_metric name, metric, [
            :count, :one_minute_rate, :five_minute_rate,
            :fifteen_minute_rate, :mean_rate
          ]
        when Metriks::Counter
          send_metric name, metric, [
            :count
          ]
        when Metriks::UtilizationTimer
          send_metric name, metric, [
            :count, :one_minute_rate, :five_minute_rate,
            :fifteen_minute_rate, :mean_rate,
            :min, :max, :mean, :stddev,
            :one_minute_utilization, :five_minute_utilization,
            :fifteen_minute_utilization, :mean_utilization,
          ], [
            :median, :get_95th_percentile
          ]
        when Metriks::Timer
          send_metric name, metric, [
            :count, :one_minute_rate, :five_minute_rate,
            :fifteen_minute_rate, :mean_rate,
            :min, :max, :mean, :stddev
          ], [
            :median, :get_95th_percentile
          ]
        when Metriks::Histogram
          send_metric name, metric, [
            :count, :min, :max, :mean, :stddev
          ], [
            :median, :get_95th_percentile
          ]
        end
      end
    end

    def send_metric(base_name, metric, keys, snapshot_keys = [])
      time = @time_tracker.now_floored

      base_name = base_name.to_s.gsub(/ +/, '_')
      if @prefix
        base_name = "#{@prefix}.#{base_name}"
      end

      keys.flatten.each do |key|
        name = key.to_s.gsub(/^get_/, '').to_s
        full_name = "#{base_name}.#{name}"
        value = metric.send(key)
        if name == "count"
          @agent.increment(full_name, value, time)
        else
          @agent.gauge(full_name, value, time)
        end
      end

      unless snapshot_keys.empty?
        snapshot = metric.snapshot
        snapshot_keys.flatten.each do |key|
          name = key.to_s.gsub(/^get_/, '').to_s
          full_name = "#{base_name}.#{name}"
          value = snapshot.send(key)
          if name == "count"
            @agent.increment(full_name, value, time)
          else
            @agent.gauge(full_name, value, time)
          end
        end
      end

    end
  end
end
