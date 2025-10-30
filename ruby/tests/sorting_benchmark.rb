require "json"
require "time"

class SortingBenchmarkTest
  attr_reader :name

  def initialize(n = 10000)
    @name = "SortingBenchmark"
    @n = n
  end

  def run_once
    data = Array.new(@n) { rand(1_000_000) }
    t0 = Process.clock_gettime(Process::CLOCK_MONOTONIC)
    data.sort!
    duration = Process.clock_gettime(Process::CLOCK_MONOTONIC) - t0
    ops = @n * Math.log2(@n)
    {
      "time_s" => duration,
      "ops" => ops,
      "ops_per_sec" => ops / (duration > 0 ? duration : 1e-9),
      "checksum" => data[0, 100].sum
    }
  end

  def run(runs = 5, intrations = nil)
    results = Array.new(runs) { run_once }
    times = results.map { |r| r["time_s"] }.sort
    ops = results.map { |r| r["ops_per_sec"] }.sort
    median = runs / 2
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
  test = SortingBenchmarkTest.new(10000)
  result = test.run
  File.write("results_ruby_sorting_benchmark.json", JSON.pretty_generate(result))
end
