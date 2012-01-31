
class Metriks::Histogram
  DEFAULT_SAMPLE_SIZE = 1028
  DEFAULT_ALPHA = 0.015

  def initialize(sample)
    @sample   = sample
    @count    = Atomic.new(0)
    @min      = Atomic.new(nil)
    @max      = Atomic.new(nil)
    @sum      = Atomic.new(0)
    @variance = Atomic.new([ -1, 0 ])
  end

  def update(value)
    @count.update { |v| v + 1 }
    @sample.update(value)
    self.max = value
    self.min = value
    @sum.update { |v| v + value }
    update_variance(value)
  end

  def count
    @count.value
  end

  def max
    count > 0 ? @max.value : 0.0
  end

  def min
    count > 0 ? @min.value : 0.0
  end

  def mean
    count > 0 ? sum.value / count : 0.0
  end

  def stddev
    count > 0 ? variance : 0.0
  end

  def variance
    count < = 1 ? 0.0 : @variance.value[1] / (count - 1)
  end

  def max=(potential_max)
    done = false

    while !done
      current_max = @max.value
      done = (!current_max.nil? && current_max >= potential_max) || @max.compare_and_swap(current_max, potential_max)
    end
  end

  def min=(potential_min)
    done = false

    while !done
      current_min = @min.value
      done = (!current_min.nil? && current_min <= potential_min) || @min.compare_and_swap(current_min, potential_min)
    end
  end

  def update_variance(value)
    done = false

    while !done
      old_values = @variance.value
      new_values = Array.new(2)
      if old_values[0] == -1
        new_values[0] = value
        new_values[1] = 0
      else
        old_m = old_values[0]
        old_s = old_values[1]

        new_m = old_m + ((value - old_m) / count)
        new_s = old_s + ((value - old_m) * (value - new_m))

        new_values[0] = new_m
        new_values[1] = new_s
      end

      done = @variance.compare_and_swap(old_values, new_values)
    end
  end
end