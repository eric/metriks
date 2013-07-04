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
      Metriks::Reporter::FlatteningRegistryEnumerator.new(@registry).each do |name, value|
        write_metric(name, value)
      end
    end

    def write_metric(name, value)
      time = Time.now.to_i

      if @prefix
        name = "#{@prefix}.#{name}"
      end

      socket.write("#{name} #{value} #{time}\n")
    rescue Errno::EPIPE
      socket.close
    end
  end
end
