require 'socket'
require 'metriks/reporter'
require 'metriks/registry'
require 'metriks/time_tracker'

class Metriks::Reporter
  class Graphite < Metriks::Reporter
    attr_accessor :host, :port, :prefix

    def initialize(host, port, options = {})
      @host   = host
      @port   = port
      @prefix = options[:prefix]

      super options
    end

    def socket
      @socket = nil if @socket && @socket.closed?
      @socket ||= TCPSocket.new(@host, @port)
    end

    def write
      time = Time.now.to_i

      @registry.each do |base_name, metric|
        base_name = base_name.to_s.gsub(/ +/, '_')
        base_name = "#{@prefix}.#{base_name}" if @prefix

        metric.each do |name, value|
          socket.write("#{base_name}.#{name} #{value} #{time}\n")
        end
      end
    end
  end
end
