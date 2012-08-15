require 'test/unit'
require 'mocha'
require 'metriks/reporter/proc_title'

Thread.abort_on_exception = true

class ProcTitleReporterIsolatedTest < Test::Unit::TestCase
  def setup
    @original_proctitle = $0.dup
  end

  def teardown
    $0 = @original_proctitle
  end

  ### Options

  def test_round_to_one_decimal_place_and_use_proctitle_as_prefix_by_default
    reporter = Metriks::Reporter::ProcTitle.new
    reporter.add('pi') { 3.1415926	}
    reporter.write
    assert_equal "#{ @original_proctitle } pi: 3.1", $0
  end

  def test_specify_rounding
    reporter = Metriks::Reporter::ProcTitle.new :rounding => 2
    reporter.add('pi') { 3.1415926	}
    reporter.write
    assert_equal "#{ @original_proctitle } pi: 3.14", $0
  end

  def test_ignore_rounding_for_non_floats
    reporter = Metriks::Reporter::ProcTitle.new
    reporter.add('pi') { '3.1415926'	}
    reporter.write
    assert_equal "#{ @original_proctitle } pi: 3.1415926", $0
  end

  def test_specify_prefix
    reporter = Metriks::Reporter::ProcTitle.new :prefix => 'metriks!'
    reporter.add('counter') { 1 }
    reporter.write
    assert_equal 'metriks! counter: 1', $0
  end

  ### Public Methods

  def test_empty_with_no_metrics
    reporter = Metriks::Reporter::ProcTitle.new
    assert reporter.empty?
  end

  def test_empty_with_metrics
    reporter = Metriks::Reporter::ProcTitle.new
    reporter.add 'counter'
    assert !reporter.empty?
  end

  def test_write_with_no_metrics
    Metriks::Reporter::ProcTitle.new.write
    assert_equal @original_proctitle, $0
  end

  def test_write
    reporter = Metriks::Reporter::ProcTitle.new
    reporter.add('counter') { 1 }
    reporter.write
    assert_equal "#{ @original_proctitle } counter: 1", $0
  end

  def test_writing_several_metrics
    reporter = Metriks::Reporter::ProcTitle.new
    reporter.add('counter') { 1 }
    reporter.add('pi') { 3.1415926	}
    reporter.write
    assert_equal "#{ @original_proctitle } counter: 1 pi: 3.1", $0
  end

  def test_metric_suffix
    reporter = Metriks::Reporter::ProcTitle.new
    reporter.add('counter', 'ms') { 1 }
    reporter.add('pi', '%')       { 3.1415926	}
    reporter.add('gold')          { 1.6180339 }
    reporter.write
    assert_equal "#{ @original_proctitle } counter: 1/ms pi: 3.1% gold: 1.6", $0
  end
end
