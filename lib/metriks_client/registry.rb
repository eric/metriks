require 'metriks_client/counter'

class MetriksClient::Registry
  def initialize
    @mutex   = Mutex.new
    @metrics = {}
  end

  def counter(name)
    @mutex.synchronize do
      if metric = @metrics[name] && !metric.is_a?(Counter)
        raise "Metric already defined as '#{metric.class}'"
      elsif metric
        return metric
      else
        @counters[name] = Counter.new
      end
    end
  end
end