#!/usr/bin/env ruby

require 'benchmark'
require 'metriks'


def fib(n)
  n < 2 ? n : fib(n-1) + fib(n-2)
end

uniform_timer     = Metriks::Timer.new(Metriks::Histogram.new_uniform)
exponential_timer = Metriks::Timer.new(Metriks::Histogram.new_exponentially_decaying)

fib_times = ARGV[0] ? ARGV[0].to_i : 10
iter      = ARGV[1] ? ARGV[1].to_i : 100000

puts "fib(#{fib_times}): #{iter} iterations"
puts "-" * 50

plain = Benchmark.realtime do
  for i in 1..iter
    fib(fib_times)
  end
end

puts "%15s: %f secs %f secs/call" % [ 'plain', plain, plain / iter ]

uniform = Benchmark.realtime do
  for i in 1..iter
    uniform_timer.time do
      fib(fib_times)
    end
  end
end

puts "%15s: %f secs %f secs/call -- %.1f%% slower than plain (%f secs/call)" % [ 
  'uniform', uniform, uniform / iter, 
  (uniform - plain) / plain * 100 ,
  (uniform - plain) / iter,
]

exponential = Benchmark.realtime do
  for i in 1..iter
    exponential_timer.time do
      fib(fib_times)
    end
  end
end

puts "%15s: %f secs %f secs/call -- %.1f%% slower than plain (%f secs/call) -- %.1f%% slower than uniform (%f secs/call)" % [ 
  'exponential', exponential, exponential / iter, 
  (exponential - plain) / plain * 100 ,
  (exponential - plain) / iter,
  (exponential - uniform) / uniform * 100 ,
  (exponential - uniform) / iter
]


