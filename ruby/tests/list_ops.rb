require "json"

class ListOpsTest
  attr_reader :name

  def initialize(ops_per_iter = 1_000_000)
    @name = "ListOps"
    @ops_per_iter = ops_per_iter
  end

  def workload
    arr = []
    # Append phase
    5000.times { |i| arr << i }
    # Random insertions
    500.times do
      idx = rand(0..arr.length)
      arr.insert(idx, rand(0..100))
    end
    # Random deletions
    500.times do
      break if arr.empty?
      idx = rand(0...arr.length)
      arr.delete_at(idx)
    end
    # Access phase
    s = 0
    1000.times { s += arr[rand(0...arr.length)] }
    s
  end

  def run_once(iterations)
    reps = [1, iterations / 1000].max
    t0 = Process.clock_gettime(Process::CLOCK_MONOTONIC)
    total = 0
    reps.times { total += workload }
    t1 = Process.clock_gettime(Process::CLOCK_MONOTONIC)
    duration = t1 - t0
    ops_done = reps * 1000
    {
      "time_s" => duration,
      "ops" => ops_done,
      "ops_per_sec" => ops_done / (duration > 0 ? duration : 1e-9),
      "acc" => total,
      "gc_stat_after" => GC.stat
    }
  end

  def run(runs = 5, iterations = nil)
    iterations ||= @ops_per_iter
    results = []
    runs.times do
      results << run_once(iterations)
      GC.start
    end
    times = results.map { |r| r["time_s"] }.sort
    ops = results.map { |r| r["ops_per_sec"] }.sort
    {
      "name" => @name,
      "runs" => runs,
      "median_time_s" => times[times.length / 2],
      "median_ops_per_sec" => ops[ops.length / 2],
      "raw" => results
    }
  end
end

if __FILE__ == $0
  t = ListOpsTest.new
  puts JSON.pretty_generate(t.run)
end
