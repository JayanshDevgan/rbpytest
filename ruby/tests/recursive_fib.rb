require "time"
require "json"

class RecursiveFibTest
  attr_reader :name

  def initialize(n = 20)
    @name = "RecursiveFibonacci"
    @n = n
    @memo = {}
  end

  # ✅ Safe recursive Fibonacci with memoization
  def fib(x)
    return x if x < 2
    return @memo[x] if @memo.key?(x)

    @memo[x] = fib(x - 1) + fib(x - 2)
  end

  def run_once
    @memo.clear   # reset memo for clean measurement

    t0 = Process.clock_gettime(Process::CLOCK_MONOTONIC)
    result = fib(@n)
    duration = Process.clock_gettime(Process::CLOCK_MONOTONIC) - t0

    {
      "time_s" => duration,
      "result" => result,
      "ops_per_sec" => 1.0 / (duration > 0 ? duration : 1e-9)
    }
  end

  # ✅ Accepts (runs, iterations) because C runner passes 2 args
  def run(runs = 3, iterations = nil)
    results = Array.new(runs) { run_once }
    times = results.map { |r| r["time_s"] }.sort
    ops   = results.map { |r| r["ops_per_sec"] }.sort

    mid = runs / 2

    {
      "name" => @name,
      "runs" => runs,
      "median_time_sec" => times[mid],
      "median_ops_per_sec" => ops[mid],
      "raw" => results
    }
  end
end

# ✅ Required alias for your C test harness
RecursiveFibTestTest = RecursiveFibTest

if __FILE__ == $0
  test = RecursiveFibTest.new(24)
  result = test.run
  File.write("results_ruby_recursive_fib.json", JSON.pretty_generate(result))
  puts JSON.pretty_generate(result)
end
