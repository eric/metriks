require 'metriks/counter'
require 'metriks/timer'
require 'metriks/utilization_timer'
require 'metriks/meter'

module Metriks
  class Registry
    def self.default
      @default ||= new
    end

    def initialize
      @mutex = Mutex.new
      @metrics = {}
    end

    def clear
      @mutex.synchronize do
        @metrics.each do |key, metric|
          metric.stop if metric.respond_to?(:stop)
        end

        @metrics = {}
      end
    end

    def stop
      clear
    end

    def counter(name)
      add_or_get(name, Metriks::Counter)
    end

    def timer(name)
      add_or_get(name, Metriks::Timer)
    end

    def utilization_timer(name)
      add_or_get(name, Metriks::UtilizationTimer)
    end

    def meter(name)
      add_or_get(name, Metriks::Meter)
    end

    def get(name)
      @mutex.synchronize do
        @metrics[name]
      end
    end

    def add(name, metric)
      @mutex.synchronize do
        if @metrics[name]
          raise "Metric '#{name}' already defined"
        else
          @metrics[name] = metric
        end
      end
    end

    protected
    def add_or_get(name, klass)
      @mutex.synchronize do
        if metric = @metrics[name]
          if !metric.is_a?(klass)
            raise "Metric already defined as '#{metric.class}'"
          else
            return metric
          end
        else
          @metrics[name] = klass.new
        end
      end
    end
  end
end