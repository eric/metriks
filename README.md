# Metriks Client

This is an experiment in making a threadsafe, low impact library to measure
aspects of your ruby.


## Installing

Everything is still in flux, so for the time being I have been installing
the gem from git with bundler.

To install, add this to your `Gemfile`:

    gem 'metriks', :git => 'git://github.com/eric/metriks.git'


## API Overview

### Counters

Basic atomic counter. Used as an underlying metric for many of the other
more advanced metrics.

``` ruby
  counter = Metriks.counter('calls')
  counter.increment

  puts "calls: #{counter.count}"
```


### Meters

A meter that measures the mean throughput and the one-, five-, and
fifteen-minute exponentially-weighted moving average throughputs.

``` ruby
  meter = Metriks.meter('requests')
  meter.mark

  puts "requests: #{meter.one_minute_rate}"
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

## Plans

An incomplete list of things I would like to see added:

* Rack middleware to measure utilization, throughput and worker time
* Basic reporters:
  * Rack endpoint returning JSON
  * Logger reporter to output metrics on a time interval
  * [Statsd](https://github.com/etsy/statsd) reporter
  * [Librato Metrics](http://metrics.librato.com) reporter
  * Proctitle reporter that updates the proc title every few seconds
* Metaprogramming instrumentation hooks like [Shopify's statsd-instrument](https://github.com/Shopify/statsd-instrument)


## Credits

Most of the inspiration for this project comes from the amazing talk that
Code Hale gave at CodeConf and his sweet
[Metrics](https://github.com/codahale/metrics) Java library.


## License

Copyright (c) 2012 Eric Lindvall

Published under the MIT License, see LICENSE