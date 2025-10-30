require "json"
require "time"
require "securerandom"

class AlgorithmicMix
  attr_reader :name

  def initialize(size = 5000, depth = 8, runs = 5)
    @name = "Algorithmic Mix"
    @size = size
    @depth = depth
    @runs = runs
  end

  # Recursive Fibonacci (small depth for realism)
  def recursive_fib(n)
    return n if n < 2
    recursive_fib(n - 1) + recursive_fib(n - 2)
  end

  # Sorting and searching test
  def sort_and_search(arr)
    arr.sort!
    target = arr[arr.length / 2]
    arr.index(target)
  end

  # File I/O cycle test with a unique temp file name
  def io_cycle(data)
    fname = "temp_mix_test_#{SecureRandom.hex(4)}.tmp"
    File.open(fname, "w") { |f| f.write(JSON.dump(data)) }
    parsed = JSON.parse(File.read(fname))
    File.delete(fname) if File.exist?(fname)
    parsed
  end

  # One full run (includes arithmetic, recursion, sort/search, file I/O)
  def run_once
    numbers = Array.new(@size) { rand(1..100_000) }

    t0 = Process.clock_gettime(Process::CLOCK_MONOTONIC)

    # Arithmetic + recursion
    math_sum = (1..500).reduce(0.0) { |acc, i| acc + Math.sin(i) * Math.sqrt((i % 100) + 1) }
    fib_val = recursive_fib(10)

    # Sorting + searching
    idx = sort_and_search(numbers)

    # File I/O
    data = { "sum" => math_sum, "fib" => fib_val, "idx" => idx, "nums" => numbers[0..50] }
    _ = io_cycle(data)

    t1 = Process.clock_gettime(Process::CLOCK_MONOTONIC)
    duration = t1 - t0

    { "duration_s" => duration, "ops_per_s" => 1.0 / (duration > 0 ? duration : 1e-9) }
  end

  # Main test runner (now compatible with automated harness)
  def run(runs = 5, iterations = nil)
    runs ||= @runs
    iterations ||= 1  # not used, but included for compatibility

    results = Array.new(runs) { run_once }
    times = results.map { |r| r["duration_s"] }.sort
    ops = results.map { |r| r["ops_per_s"] }.sort
    median_t = times[times.size / 2]
    median_ops = ops[ops.size / 2]

    {
      "name" => @name,
      "runs" => runs,
      "median_time_s" => median_t,
      "median_ops_per_s" => median_ops,
      "raw" => results
    }
  end
end

# Alias for test harness compatibility
AlgorithmicMixTestTest = AlgorithmicMix

# Execute directly if script is run standalone
if __FILE__ == $0
  result = AlgorithmicMix.new.run
  File.write("results_algorithmic_mix_ruby.json", JSON.pretty_generate(result))
  puts JSON.pretty_generate(result)
end
