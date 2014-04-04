require 'metriks/time_tracker'
require 'net/https'

module Metriks::Reporter
  class LibratoMetrics
    attr_accessor :prefix, :source, :data

    def initialize(email, token, options = {})
      @email = email
      @token = token

      @prefix = options[:prefix]
      @source = options[:source]

      @registry     = options[:registry] || Metriks::Registry.default
      @time_tracker = Metriks::TimeTracker.new(options[:interval] || 60)
      @on_error     = options[:on_error] || proc { |ex| }

      @data = {}
      @sent = {}

      @last = Hash.new { |h,k| h[k] = 0 }

      if options[:percentiles]
        @percentiles = options[:percentiles]
      else
        @percentiles = [ 0.95, 0.999 ]
      end
    end

    def start
      @thread ||= Thread.new do
        while true
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

    def submit
      return if @data.empty?

      url = URI.parse('https://metrics-api.librato.com/v1/metrics')
      req = Net::HTTP::Post.new(url.path)
      req.basic_auth(@email, @token)
      req.set_form_data(@data)

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

      @data.clear
    end

    def write
      time = @time_tracker.now_floored

      @registry.each do |name, metric|
        name = name.to_s.gsub(/ +/, '_')

        if prefix
          name = "#{prefix}.#{name}"
        end

        case metric
        when Metriks::Meter
          count = metric.count
          datapoint(name, count - @last[name], time, :display_min => 0,
            :summarize_function => 'sum')
          @last[name] = count
        when Metriks::Counter
          datapoint(name, metric.count, time, :summarize_function => 'average')
        when Metriks::Gauge
          datapoint(name, metric.value, time, :summarize_function => 'average')
        when Metriks::Histogram, Metriks::Timer, Metriks::UtilizationTimer
          if Metriks::UtilizationTimer === metric || Metriks::Timer === metric
            count = metric.count
            datapoint(name, count - @last[name], time, :display_min => 0,
              :summarize_function => 'sum')
            @last[name] = count
          end

          if Metriks::UtilizationTimer === metric
            datapoint("#{name}.one_minute_utilization",
              metric.one_minute_utilization, time,
              :display_min => 0, :summarize_function => 'average')
          end

          snapshot = metric.snapshot

          datapoint("#{name}.median", snapshot.median, time, :display_min => 0,
            :summarize_function => 'average')

          @percentiles.each do |percentile|
            percentile_name = (percentile * 100).to_f.to_s.gsub(/0+$/, '').gsub('.', '')
            datapoint("#{name}.#{percentile_name}th_percentile",
              snapshot.value(percentile), time, :display_min => 0,
              :summarize_function => 'max')
          end
        end
      end

      if @data.length > 0
        submit
      end
    end

    def datapoint(name, value, time, attributes = {})
      idx = @data.length

      if prefix
        name = "#{prefix}.#{name}"
      end

      @data["gauges[#{idx}][name]"]         = name
      @data["gauges[#{idx}][source]"]       = @source
      @data["gauges[#{idx}][measure_time]"] = time.to_i
      @data["gauges[#{idx}][value]"]        = value

      unless @sent[name]
        @sent[name] = true

        @data["gauges[#{idx}][period]"] = @time_tracker.interval
        @data["gauges[#{idx}][attributes][aggregate]"] = true

        attributes.each do |k, v|
          @data["gauges[#{idx}][attributes][#{k}]"] = v
        end
      end
    end
  end
end
