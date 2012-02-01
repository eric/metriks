# Metriks Client

This is an experiment in making a threadsafe, low impact library to measure
aspects of your ruby.

## Overview

### Counters

Basic atomic counter. Used as an underlying metric for many of the other
more advanced metrics.

    counter = Metriks.counter('calls')
    counter.increment

    puts "calls: #{counter.count}" #=> "calls: 1"


### Meters

A meter that measures the mean throughput and the one-, five-, and
fifteen-minute exponentially-weighted moving average throughputs.

    meter = Metriks.meter('requests')
    meter.mark

    puts "requests: #{meter.one_minute_rate}"


### Timers

A timer that measures the average time as well as throughput metrics via
a meter.

    timer = Metriks.timer('requests')
    timer.time do
      work
    end

    t = timer.time
    work
    t.stop

    puts "average request time: #{timer.mean}"
    puts "rate: #{timer.five_minute_rate}/sec"


### Utilization Timer

A specialized timer that calculates the percentage (between 0 and 1) of
wall-clock time that was spent.


    timer = Metriks.timer('requests')
    timer.time do
      work
    end

    t = timer.time
    work
    t.stop

    puts "average request time: #{timer.mean}"
    puts "utilization: #{timer.one_minute_rate * 100.0}%"


## Credits

Most of the inspiration for this project comes from the amazing talk that
Code Hale gave at CodeConf and his sweet
[Metrics](https://github.com/codahale/metrics) Java library.


## License

Copyright (c) 2012 Eric Lindvall

Published under the MIT License, see LICENSE