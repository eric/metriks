require 'socket'

module Metriks::Reporter
  class Graphite
    attr_reader :host, :port, :percentile_methods

    def initialize(host, port, options = {})
      @host = host
      @port = port

      @prefix = options[:prefix]

      @registry = options[:registry] || Metriks::Registry.default
      @interval = options[:interval] || 60
      @on_error = options[:on_error] || proc { |ex| }

      @percentile_methods = Metriks::Snapshot.methods_for_percentiles(options[:percentiles] || :p95)
    end

    def socket
      @socket = nil if @socket && @socket.closed?
      @socket ||= TCPSocket.new(@host, @port)
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
      @registry.each do |name, metric|
        write_metric name, metric, metric.class.reportable_metrics,
          metric.class.reportable_snapshot_metrics(:percentiles => percentile_methods)
      end
    end

    def write_metric(base_name, metric, keys, snapshot_keys = [])
      time = Time.now.to_i

      base_name = base_name.to_s.gsub(/ +/, '_')
      if @prefix
        base_name = "#{@prefix}.#{base_name}"
      end

      keys.flatten.each do |key|
        name = key.to_s.gsub(/^get_/, '')
        value = metric.send(key)
        socket.write("#{base_name}.#{name} #{value} #{time}\n")
      end

      unless snapshot_keys.empty?
        snapshot = metric.snapshot
        snapshot_keys.flatten.each do |key|
          name = key.to_s.gsub(/^get_/, '')
          value = snapshot.send(key)
          socket.write("#{base_name}.#{name} #{value} #{time}\n")
        end
      end
    rescue Errno::EPIPE
      socket.close
    end
  end
end
