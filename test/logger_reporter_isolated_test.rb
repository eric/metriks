require 'test/unit'
require 'mocha'
require 'metriks/reporter/logger'

Thread.abort_on_exception = true

class LoggerReporterIsolatedTest < Test::Unit::TestCase
  ### Options

  def test_specify_log_level
    reporter = Metriks::Reporter::Logger.new(:log_level => 42)
    assert_equal 42, reporter.log_level
  end

  def test_default_log_level_info
    reporter = Metriks::Reporter::Logger.new
    assert_equal ::Logger::INFO, reporter.log_level
  end

  def test_assign_log_level
    reporter = Metriks::Reporter::Logger.new
    reporter.log_level = 42
    assert_equal 42, reporter.log_level
  end

  def test_specify_logger
    logger = stub :logger
    reporter = Metriks::Reporter::Logger.new(:logger => logger)
    assert_equal logger, reporter.logger
  end

  def test_default_logger_uses_stdout
    logger = stub :logger
    ::Logger.expects(:new).with(STDOUT).returns(logger)
    reporter = Metriks::Reporter::Logger.new
    assert_equal logger, reporter.logger
  end

  def test_assign_logger
    logger = stub :logger
    reporter = Metriks::Reporter::Logger.new
    reporter.logger = logger
    assert_equal logger, reporter.logger
  end

  def test_use_logger_and_log_level
    log_level = stub :log_level
    logger    = stub :logger
    metric = stub do
      stubs :type => 'counter'
      stubs(:each).yields([ 'count', 1 ])
    end
    registry = stub do
      stubs(:each).yields('testing', metric)
    end
    reporter = Metriks::Reporter::Logger.new(:logger    => logger,
                                             :registry  => registry,
                                             :log_level => log_level)
    logger.expects(:add).with(log_level, kind_of(String))
    reporter.write
  end

  def test_specify_prefix
    reporter = Metriks::Reporter::Logger.new(:prefix => 'prefix')
    assert_equal 'prefix', reporter.prefix
  end

  def test_default_prefix
    reporter = Metriks::Reporter::Logger.new
    assert_equal 'metriks:', reporter.prefix
  end

  def test_assign_prefix
    reporter = Metriks::Reporter::Logger.new
    reporter.prefix = 'prefix'
    assert_equal 'prefix', reporter.prefix
  end

  def test_use_prefix
    logger = stub :logger
    metric = stub do
      stubs :type => 'counter'
      stubs(:each).yields([ 'count', 1 ])
    end
    registry = stub do
      stubs(:each).yields('testing', metric)
    end
    reporter = Metriks::Reporter::Logger.new(:logger   => logger,
                                             :registry => registry,
                                             :prefix   => 'prefix')
    logger.expects(:add).with do |_, message|
      assert message.start_with?('prefix')
    end
    reporter.write
  end

  ### Public Methods

  def test_write_includes_time
    Time.stubs(:now => 42)
    logger = stub :logger
    metric = stub do
      stubs :type => 'counter'
      stubs(:each).yields([ 'count', 1 ])
    end
    registry = stub do
      stubs(:each).yields('testing', metric)
    end
    reporter = Metriks::Reporter::Logger.new(:logger   => logger,
                                             :registry => registry)
    logger.expects(:add).with do |_, message|
      assert_match /\btime=42\b/, message
    end
    reporter.write
  end

  def test_write_includes_metric
    Time.stubs(:now => 42)
    logger = stub :logger
    metric = stub do
      stubs :type => 'counter'
      stubs(:each).yields([ 'count', 1 ])
    end
    registry = stub do
      stubs(:each).yields('testing', metric)
    end
    reporter = Metriks::Reporter::Logger.new(:logger   => logger,
                                             :registry => registry)

    expected = 'metriks: time=42 name=testing type=counter count=1'
    logger.expects(:add).with(kind_of(Fixnum), expected)
    reporter.write
  end

  def test_writes_multiple_metrics
    Time.stubs(:now => 42)
    logger = stub :logger
    metric_one = stub do
      stubs :type => 'one'
      stubs(:each).yields([ 'one', 1.1 ])
    end
    metric_two = stub do
      stubs :type => 'two'
      stubs(:each).multiple_yields([ 'two',   2.2 ],
                                   [ 'three', 3.3 ])
    end
    registry = stub do
      stubs(:each).multiple_yields([ 'metric_one', metric_one ],
                                   [ 'metric_two', metric_two ])
    end
    reporter = Metriks::Reporter::Logger.new(:logger   => logger,
                                             :registry => registry)
    expected = 'metriks: time=42 name=metric_one type=one one=1.1'
    logger.expects(:add).with(kind_of(Fixnum), expected)
    expected = 'metriks: time=42 name=metric_two type=two two=2.2 three=3.3'
    logger.expects(:add).with(kind_of(Fixnum), expected)
    reporter.write
  end

  def test_write_records_times_once_per_write
    metric_one = stub do
      stubs :type => 'one'
      stubs(:each).yields([ 'one', 1.1 ])
    end
    metric_two = stub do
      stubs :type => 'two'
      stubs(:each).multiple_yields([ 'two',   2.2 ],
                                   [ 'three', 3.3 ])
    end
    registry = stub do
      stubs(:each).multiple_yields([ 'metric_one', metric_one ],
                                   [ 'metric_two', metric_two ])
    end
    logger = stub :logger
    reporter = Metriks::Reporter::Logger.new(:logger   => logger,
                                             :registry => registry)
    time = stub :time
    Time.expects(:now).once.returns(time)
    time.expects(:to_i).at_least_once.returns(42)
    logger.expects(:add).at_least_once
    reporter.write
  end
end
