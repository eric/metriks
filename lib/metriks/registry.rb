require 'metriks/counter'
require 'metriks/timer'
require 'metriks/utilization_timer'
require 'metriks/meter'

class Metriks::Registry
  def initialize
    @mutex   = Mutex.new
    @metrics = {}
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
      if metric = @metrics[name] && !metric.is_a?(klass)
        raise "Metric already defined as '#{metric.class}'"
      elsif metric
        return metric
      else
        @metrics[name] = klass.new
      end
    end
  end
end