require "json"

class LogicControlTest
  attr_reader :name

  def initialize(ops_per_iter = 10_000_000)
    @name = "LogicControl"
    @ops_per_iter = ops_per_iter
  end

  def workload
    acc = 0
    (1..499).each do |i|
      if i % 15 == 0
        acc += i * 2
      elsif i % 5 == 0
        acc -= i
      elsif i % 3 == 0
        acc += i / 2
      else
        acc += (i & 1)
      end
    end
    acc
  end

  def run_once(iterations)
    reps = [1, iterations / 1000].max
    t0 = Process.clock_gettime(Process::CLOCK_MONOTONIC)
    acc = 0
    reps.times { acc += workload }
    t1 = Process.clock_gettime(Process::CLOCK_MONOTONIC)
    duration = t1 - t0
    ops_done = reps * 1000
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

if __FILE__ == $0
  t = LogicControlTest.new
  puts JSON.pretty_generate(t.run)
end
