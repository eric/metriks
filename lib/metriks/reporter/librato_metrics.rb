require 'metriks/time_tracker'
require 'net/https'
require 'metriks/reporter/flattening_registry_enumerator'

module Metriks::Reporter
  class LibratoMetrics
    attr_accessor :prefix, :source

    def initialize(email, token, options = {})
      @email = email
      @token = token

      @prefix = options[:prefix]
      @source = options[:source]

      @registry     = options[:registry] || Metriks::Registry.default
      @time_tracker = Metriks::TimeTracker.new(options[:interval] || 60)
      @on_error     = options[:on_error] || proc { |ex| }
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

    def write
      time  = @time_tracker.now_floored

      enumerator = Metriks::Reporter::FlatteningRegistryEnumerator.new(@registry)

      data = {}

      enumerator.each_with_index do |name, value, klass, idx|
        if prefix
          name = "#{prefix}.#{name}"
        end

        data["gauges[#{idx}][name]"] = name.to_s
        data["gauges[#{idx}][source]"] = @source
        data["gauges[#{idx}][measure_time]"] = time.to_i
        data["gauges[#{idx}][value]"] = value
      end

      submit(data)
    end
  end
end
