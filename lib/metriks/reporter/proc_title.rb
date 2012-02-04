module Metriks::Reporter
  class ProcTitle
    def initialize(options = {})
      @interval = options[:interval] || 5
      @rounding = options[:rounding] || 1

      @prefix   = $0.dup
      @metrics  = []
    end

    def add(name, suffix = nil, &block)
      @metrics << [ name, suffix, block ]
    end

    def empty?
      @metrics.empty?
    end

    def start
      @thread ||= Thread.new do
        loop do
          begin
            unless @metrics.empty?
              $0 = "#{@prefix} #{generate_title}"
            end
          rescue Exception => e
          end
          sleep @interval
        end
      end
    end

    def stop
      @thread.kill if @thread
      @thread = nil
    end

    protected
    def generate_title
      @metrics.collect do |name, suffix, block|
        val = block.call
        val = "%.#{@rounding}f" % val if val.is_a?(Float)

        if suffix
          "#{name}: #{val}/#{suffix}"
        else
          "#{name}: #{val}"
        end
      end.join(' ')
    end
  end
end