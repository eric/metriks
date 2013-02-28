require 'metriks/time_tracker'
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
      gauges = []
      @registry.each do |name, metric|
        gauges << prepare_metrics(name, metric.export_values)
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

    def form_data(metrics)
      data = {}

      gauges = metrics.select { |m| m[:type] == "gauge" }

      gauges.each_with_index do |gauge, idx|
        gauge.each do |key, value|
          if value
            data["gauges[#{idx}][#{key}]"] = value.to_s
          end
        end
      end

      counters = metrics.select { |m| m[:type] == "counter" }

      counters.each_with_index do |counter, idx|
        counter.each do |key, value|
          if value
            data["counters[#{idx}][#{key}]"] = value.to_s
          end
        end
      end

      data
    end

    def prepare_metrics(base_name, metrics)
      results = []
      time = @time_tracker.now_floored

      base_name = base_name.to_s.gsub(/ +/, '_')
      if @prefix
        base_name = "#{@prefix}.#{base_name}"
      end

      metrics.each_pair do |name, value|
        results << {
          :type => name.to_s == "count" ? "counter" : "gauge",
          :name => "#{base_name}.#{name}",
          :source => @source,
          :measure_time => time,
          :value => value
        }
      end

      results
    end
  end
end
