require 'atomic'
require 'rbtree'
require 'metriks/snapshot'

module Metriks
  class ExponentiallyDecayingSample
    RESCALE_THRESHOLD = 60 * 60 # 1 hour

    def initialize(reservoir_size, alpha)
      @values = RBTree.new
      @count = Atomic.new(0)
      @next_scale_time = Atomic.new(0)
      @alpha = alpha
      @reservoir_size = reservoir_size
      @mutex = Mutex.new
      clear
    end

    def clear
      @mutex.synchronize do
        @values.clear
        @count.value = 0
        @next_scale_time.value = Time.now + RESCALE_THRESHOLD
        @start_time = Time.now
      end
    end

    def size
      count = @count.value
      count < @reservoir_size ? count : @reservoir_size
    end

    def snapshot
      @mutex.synchronize do
        Snapshot.new(@values.values)
      end
    end

    def update(value, timestamp = Time.now)
      @mutex.synchronize do
        priority = weight(timestamp - @start_time) / rand
        new_count = @count.update { |v| v + 1 }
        if new_count <= @reservoir_size
          @values[priority] = value
        else
          first_priority = @values.first[0]
          if first_priority < priority
            unless @values[priority]
              @values[priority] = value

              until @values.delete(first_priority)
                first_priority = @values.first[0]
              end
            end
          end
        end
      end

      now = Time.new
      next_time = @next_scale_time.value
      if now >= next_time
        rescale(now, next_time)
      end
    end

    def weight(time)
      Math.exp(@alpha * time)
    end

    def rescale(now, next_time)
      if @next_scale_time.compare_and_swap(next_time, now + RESCALE_THRESHOLD)
        @mutex.synchronize do
          old_start_time = @start_time
          @start_time = Time.now
          keys = @values.keys
          keys.each do |key|
            value = @values.delete(key)
            @values[key* Math.exp(-@alpha * (@start_time - old_start_time))] = value
          end
        end
      end
    end
  end
end