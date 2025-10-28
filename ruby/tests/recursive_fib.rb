require "time"
require "json"

class RecursiveFibonacciTest
  attr_reader :name

  def initialize(n = 20)
    @name = "RecursiveFibonacci"
    @n = n
  end

  def fib(x)
    return x if x < 2
    fib(x - 1) + fib(x - 2)
  end

  def run_once
    t0 = Process.clock_gettime(Process::CLOCK_MONOTONIC)
    result = fib(@n)
    duration = Process.clock_gettime(Process::CLOCK_MONOTONIC) - t0
    {
      "time_s" => duration,
      "result" => result,
      "ops_per_sec" => 1.0 / (duration > 0 ? duration : 1e-9)
    }
  end

  def run(runs = 3)
    results = Array.new(runs) { run_once }
    times = results.map { |r| r["time_s"] }.sort
    ops = results.map { |r| r["ops_per_sec"] }.sort
    median = times.length / 2
    {
      "name" => @name,
      "runs" => runs,
      "median_time_sec" => times[median],
      "median_ops_per_sec" => ops[median],
      "raw" => results
    }
  end
end

if __FILE__ == $0
  test = RecursiveFibonacciTest.new(24)
  result = test.run
  File.write("results_ruby_recursive_fib.json", JSON.pretty_generate(result))
end
