require "time"

class MemoryAccessTest
  attr_reader :name
  def initialize(ops_per_iter = 5_000_000)
    @name = "MemoryAccess"
    @ops_per_iter = ops_per_iter
  end

  def workload(size = 10_000)
    arr = Array.new(size) { |i| i }
    sum = 0
    arr.each { |v| sum += v }
    rand_idx = (0...size).to_a.shuffle
    rand_idx.each { |i| sum -= arr[i] }
    sum
  end

  def run_once(iterations)
    reps = [1, iterations / 10_000].max
    t0 = Process.clock_gettime(Process::CLOCK_MONOTONIC)
    acc = 0
    reps.times { acc += workload(10_000) }
    t1 = Process.clock_gettime(Process::CLOCK_MONOTONIC)

    duration = t1 - t0
    ops_done = reps * 10_000
    {
      "time_s" => duration,
      "ops" => ops_done,
      "ops_per_sec" => ops_done / (duration > 0 ? duration : 1e-9),
      "acc" => acc,
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
