require 'socket'

module Metriks::Reporter
  class Graphite
    attr_reader :host, :port

    def initialize(host, port, options = {})
      @host = host
      @port = port

      @prefix = options[:prefix]

      @registry  = options[:registry] || Metriks::Registry.default
      @interval  = options[:interval] || 60
      @on_error  = options[:on_error] || proc { |ex| }
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
        write_metrics name, metric.export_values
      end
    end

    def write_metrics(base_name, metrics)
      time = Time.now.to_i

      base_name = base_name.to_s.gsub(/ +/, '_')
      if @prefix
        base_name = "#{@prefix}.#{base_name}"
      end

      metrics.each_pair do |name, value|
        socket.write("#{base_name}.#{name} #{value} #{time}\n")
      end
    end
  end
end
