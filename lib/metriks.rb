
module Metriks
  VERSION = '0.9.2'

  def self.get(name)
    Metriks::Registry.default.get(name)
  end

  def self.counter(name)
    Metriks::Registry.default.counter(name)
  end

  def self.timer(name)
    Metriks::Registry.default.timer(name)
  end

  def self.utilization_timer(name)
    Metriks::Registry.default.utilization_timer(name)
  end

  def self.meter(name)
    Metriks::Registry.default.meter(name)
  end
end

require 'metriks/registry'
require 'metriks/reporter/proc_title'
