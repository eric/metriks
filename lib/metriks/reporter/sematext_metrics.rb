module Metriks::Reporter
  class SematextMetrics

    require 'sematext/metrics'

    def initialize(options = {})
      @client = options[:client]
      @client ||= ::Sematext::Metrics::Client.sync(options[:token])
      @interval = options[:interval] || 60
      @registry = options[:registry] || Metriks::Registry.default
      @on_error = options[:on_error] || proc { |ex| }
    end

    def start
      @tread ||= Thread.new do
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
    
    def write
      datapoints = []
      @registry.each do |name, metric|
        datapoints += case metric
        when Metriks::Counter
          [
           create_datapoints(name, metric, [:count], [:min, :max, :avg])
          ]
        when Metriks::Gauge
          [
           create_datapoints(name, metric, [:value], [:min, :max, :avg])
          ]
        when Metriks::Meter
          [                       
           create_datapoints(name, metric, [:count], [:avg], :count),
           create_datapoints(name, metric, [:mean_rate], [:avg], :rate)
          ]
        when Metriks::UtilizationTimer
          [
            create_datapoints(name, metric, [:min], [:min]),
            create_datapoints(name, metric, [:max], [:max]),
            create_datapoints(name, metric, [:mean], [:avg], :time),
            create_datapoints(name, metric, [:mean_rate], [:avg], :rate),
            create_datapoints(name, metric, [
              :mean_utilization
            ], [:avg], :utilization)
          ]
        when Metriks::Histogram
          [
           create_datapoints(name, metric, [:min], [:min]),
           create_datapoints(name, metric, [:max], [:max]),
           create_datapoints(name, metric, [:mean], [:avg]),
          ]
        when Metriks::Timer
          [
           create_datapoints(name, metric, [:min], [:min]),
           create_datapoints(name, metric, [:max], [:max]),
           create_datapoints(name, metric, [:mean], [:avg], :time),
           create_datapoints(name, metric, [:mean_rate], [:avg], :rate)
          ]
        end
      end

      datapoints.flatten!

      results = @client.send_batch datapoints
      results.each do |result|
        raise "Sending failed: #{result[:response]}" unless result[:status] == :succeed 
      end if results
    end
    
    private
    def create_datapoints(name, metric, keys, agg_types, type = nil)
      datapoints = []
      keys.each do |key|
        agg_types.each do |agg_type|
          datapoint = {
            :name => name,
            :value => metric.send(key),
            :agg_type => agg_type,
            :filter1 => "aggregation=#{agg_type}"
          }
          datapoint[:filter2] = "type=#{type}" if type
          datapoints << datapoint
        end
      end
      datapoints
    end
  end
end
