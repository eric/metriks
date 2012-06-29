require 'net/https'

module Metriks::Reporter
  class LibratoMetrics
    attr_accessor :prefix, :source

    def initialize(email, token, options = {})
      @email = email
      @token = token

      @prefix = options[:prefix]
      @source = options[:source]

      @registry  = options[:registry] || Metriks::Registry.default
      @interval  = options[:interval] || 60
      @on_error  = options[:on_error] || proc { |ex| }
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
        when Metriks::Histogram
          prepare_metric name, metric, [
            :count, :min, :max, :mean, :stddev
          ], [
            :median, :get_95th_percentile
          ]
        end
      end

      gauges.flatten!

      unless gauges.empty?
        submit(form_data(gauges.flatten))
      end
    end

    def submit(data)
      url = URI.parse('https://metrics-api.librato.com/v1/metrics')
      req = Net::HTTP::Post.new(url.path)
      req.basic_auth(@email, @token)
      req.set_form_data(data)

      http = Net::HTTP.new(url.host, url.port)
      http.verify_mode = OpenSSL::SSL::VERIFY_PEER
      http.use_ssl = true
      store = OpenSSL::X509::Store.new
      store.set_default_paths
      http.cert_store = store

      case res = http.start { |http| http.request(req) }
      when Net::HTTPSuccess, Net::HTTPRedirection
        # OK
      else
        res.error!
      end
    end

    def form_data(gauges)
      data = {}

      gauges.each_with_index do |gauge, idx|
        gauge.each do |key, value|
          if value
            data["gauges[#{idx}][#{key}]"] = value.to_s
          end
        end
      end

      data
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
