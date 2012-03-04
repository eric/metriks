require 'faraday'
require 'faraday_middleware'
require 'yajl'
require 'yajl/json_gem'

module Metriks::Reporter
  class LibratoMetrics
    def self.connection
      @connection ||= Faraday::Connection.new('https://metrics-api.librato.com') do |b|
        b.use FaradayMiddleware::EncodeJson
        b.adapter Faraday.default_adapter
        b.use Faraday::Response::RaiseError
        b.use FaradayMiddleware::ParseJson, :content_type => /\bjson$/
      end.tap do |c|
        c.headers[:content_type] = 'application/json'
        c.headers[:user_agent] = "Metriks/#{Metriks::VERSION} Faraday/#{Faraday::VERSION}"
      end
    end


    def initialize(email, token, options = {})
      @email = email
      @token = token

      @prefix = options[:prefix]
      @source = options[:source]

      @registry  = options[:registry] || Metriks::Registry.default
      @interval  = options[:interval] || 60
      @on_errror = options[:on_error] || proc { |ex| }
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

    def restart
      stop
      start
    end

    def write
      gauges = []
      @registry.each do |name, metric|
        gauges << case metric
        when Metriks::Meter
          prepare_metric name, metric, [
            :count, :one_minute_rate, :five_minute_rate,
            :fifteen_minute_rate, :mean_rate
          ]
        when Metriks::Counter
          prepare_metric name, metric, [
            :count
          ]
        when Metriks::UtilizationTimer
          prepare_metric name, metric, [
            :count, :one_minute_rate, :five_minute_rate,
            :fifteen_minute_rate, :mean_rate,
            :min, :max, :mean, :stddev,
            :one_minute_utilization, :five_minute_utilization,
            :fifteen_minute_utilization, :mean_utilization,
          ], [
            :median, :get_95th_percentile
          ]
        when Metriks::Timer
          prepare_metric name, metric, [
            :count, :one_minute_rate, :five_minute_rate,
            :fifteen_minute_rate, :mean_rate,
            :min, :max, :mean, :stddev
          ], [
            :median, :get_95th_percentile
          ]
        end
      end

      submit(:gauges => gauges.flatten)
    end

    def connection
      @connection ||= self.class.connection.dup.tap do |c|
        c.basic_auth @email, @token
      end
    end

    def submit(body)
      connection.post '/v1/metrics' do |req|
        req.body = body
      end
    end

    def prepare_metric(base_name, metric, keys, snapshot_keys = [])
      results = []
      time = Time.now.to_i

      base_name = base_name.to_s.gsub(/ +/, '_')
      if @prefix
        base_name = "#{@prefix}.#{base_name}"
      end

      keys.flatten.each do |key|
        name = key.to_s.gsub(/^get_/, '')
        value = metric.send(key)

        results << {
          :name => "#{base_name}.#{name}",
          :source => @source,
          :time => time,
          :value => value
        }
      end

      unless snapshot_keys.empty?
        snapshot = metric.snapshot
        snapshot_keys.flatten.each do |key|
          name = key.to_s.gsub(/^get_/, '')
          value = snapshot.send(key)

          results << {
            :name => "#{base_name}.#{name}",
            :source => @source,
            :time => time,
            :value => value
          }
        end
      end

      results
    end
  end
end
