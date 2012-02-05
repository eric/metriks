# Metriks Client

This is an experiment in making a threadsafe, low impact library to measure
aspects of your ruby.


## Installing

Everything is still in flux, so for the time being I have been installing
the gem from git with bundler.

To install, add this to your `Gemfile`:

    gem 'metriks', :git => 'git://github.com/eric/metriks.git'


## Metric Overview

### Counters

Basic atomic counter. Used as an underlying metric for many of the other
more advanced metrics.


#### increment(incr = 1)

Increment the counter. Without an argument it will increment by `1`.

``` ruby
  counter = Metriks.counter('calls')
  counter.increment
```

#### decrement(decr = 1)

Decrement the counter. Without an argument it will decrement by `1`.

``` ruby
  counter = Metriks.counter('calls')
  counter.decrement
```

#### count()

Return the current value of the counter.

``` ruby
  counter = Metriks.counter('calls')
  puts "counter: #{counter.count}"
```

### Meters

A meter that measures the mean throughput and the one-, five-, and
fifteen-minute exponentially-weighted moving average throughputs.

#### mark(val = 1)

Record an event with the meter. Without an argument it will record one event.

``` ruby
  meter = Metriks.meter('requests')
  meter.mark
```

#### one_minute_rate()

Returns the one-minute average rate.

``` ruby
  meter = Metriks.meter('requests')
  puts "rate: #{meter.one_minute_rater}/sec"
```

#### five_minute_rate()

Returns the five-minute average rate.

``` ruby
  meter = Metriks.meter('requests')
  puts "rate: #{meter.five_minute_rater}/sec"
```

#### fifteen_minute_rate()

Returns the fifteen-minute average rate.

``` ruby
  meter = Metriks.meter('requests')
  puts "rate: #{meter.fifteen_minute_rater}/sec"
```

### Timers

A timer that measures the average time as well as throughput metrics via
a meter.

``` ruby
  timer = Metriks.timer('requests')
  timer.time do
    work
  end

  t = timer.time
  work
  t.stop

  puts "average request time: #{timer.mean}"
  puts "rate: #{timer.five_minute_rate}/sec"
```


### Utilization Timer

A specialized timer that calculates the percentage (between 0 and 1) of
wall-clock time that was spent.

``` ruby
  timer = Metriks.utilization_timer('requests')
  timer.time do
    work
  end

  t = timer.time
  work
  t.stop

  puts "average request time: #{timer.mean}"
  puts "utilization: #{timer.one_minute_rate * 100.0}%"
```

## Reporter Overview

### Proc Title Reporter

Provides a simple way to get up-to-date statistics from a process by
updating the proctitle every 5 seconds (default).

```ruby

  reporter = Metriks::Reporter::ProcTitle.new :interval => 5

  reporter.add 'reqs', 'sec' do
    Metriks.meter('rack.requests').one_minute_rate
  end

  reporter.start
```

will display:

```
501      17015 26.0  1.9 416976 246956 ?       Ss   18:54  11:43 thin reqs: 273.3/sec
```


## Plans

An incomplete list of things I would like to see added:

* Rack middleware to measure utilization, throughput and worker time
* Basic reporters:
  * Rack endpoint returning JSON
  * Logger reporter to output metrics on a time interval
  * [Statsd](https://github.com/etsy/statsd) reporter
  * [Librato Metrics](http://metrics.librato.com) reporter
* Metaprogramming instrumentation hooks like [Shopify's statsd-instrument](https://github.com/Shopify/statsd-instrument)


## Credits

Most of the inspiration for this project comes from the amazing talk that
Code Hale gave at CodeConf and his sweet
[Metrics](https://github.com/codahale/metrics) Java library.


## License

Copyright (c) 2012 Eric Lindvall

Published under the MIT License, see LICENSE