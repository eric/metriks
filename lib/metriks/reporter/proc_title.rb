module Metriks::Reporter
  class ProcTitle
    def initialize(options = {})
      @interval  = options[:interval] || 5
      @rounding  = options[:rounding] || 1
      @on_errror = options[:on_error] || proc { |ex| }

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
              title = generate_title
              if title && !title.empty?
                $0 = "#{@prefix} #{title}"
              end
            end
          rescue Exception => ex
            @on_errror[ex] rescue nil
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