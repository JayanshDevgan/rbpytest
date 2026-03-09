require 'json'
require 'time'

class AlgorithmicMixTest
  def initialize(size = 5000, depth = 8, runs = 5)
    @name = "Algorithmic Mix"
    @size = size
    @depth = depth
    @runs = runs
  end

  attr_reader :name

  def _recursive_fib(n)
    return n if n < 2
    _recursive_fib(n - 1) + _recursive_fib(n - 2)
  end

  def _sort_and_search(arr)
    arr.sort!
    target = arr[arr.length / 2]
    arr.index(target)
  end

  def _io_cycle(data)
    fname = "temp_mix_test.tmp"
    File.open(fname, "w") do |f|
      f.write(JSON.generate(data))
    end
    result = nil
    File.open(fname, "r") do |f|
      result = JSON.parse(f.read)
    end
    File.delete(fname)
    result
  end

  def run_once
    numbers = (1..[@size, 5000].min).map { rand(1..100000) }  # Cap to safe size

    t0 = Process.clock_gettime(Process::CLOCK_MONOTONIC)
    math_sum = (1..499).sum { |i| Math.sin(i) * Math.sqrt(i % 100 + 1) }
    fib_val = _recursive_fib(10)
    idx = _sort_and_search(numbers.dup)  # dup to avoid modifying original
    _ = _io_cycle({"sum" => math_sum, "fib" => fib_val, "idx" => idx, "nums" => numbers[0..49]})
    t1 = Process.clock_gettime(Process::CLOCK_MONOTONIC)

    duration = t1 - t0
    {"duration_s" => duration, "ops_per_s" => duration > 0 ? 1.0 / duration : 0}
  end

  def run(runs = nil, iterations = nil)
    @runs = runs if runs
    @size = [@size, 5000].min if iterations  # Avoid huge freeze

    results = (1..@runs).map { run_once }
    times = results.map { |r| r["duration_s"] }.sort
    ops = results.map { |r| r["ops_per_s"] }.sort
    {
      "name" => @name,
      "runs" => @runs,
      "median_time_sec" => times[times.length / 2],
      "median_ops_per_sec" => ops[ops.length / 2],
      "raw" => results
    }
  end
end

if __FILE__ == $0
  result = AlgorithmicMixTest.new.run
  File.open("results_algorithmic_mix_ruby.json", "w") do |f|
    f.write(JSON.pretty_generate(result))
  end
  puts JSON.generate(result)
end