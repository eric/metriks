require 'socket'
require 'metriks/registry'
require 'metriks/time_tracker'

module Metriks::Reporter
  class Graphite
    attr_accessor :host, :port, :prefix

    def initialize(host, port, options = {})
      @host   = host
      @port   = port
      @prefix = options[:prefix]

      @registry     = options[:registry] || Metriks::Registry.default
      @time_tracker = Metriks::TimeTracker.new(options[:interval] || 60)
      @on_error     = options[:on_error] || proc { |ex| }
    end

    def socket
      @socket = nil if @socket && @socket.closed?
      @socket ||= TCPSocket.new(@host, @port)
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
