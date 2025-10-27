require "json"

class StringOpsTest
  attr_reader :name

  def initialize(ops_per_iter = 500_000)
    @name = "StringOps"
    @ops_per_iter = ops_per_iter
  end

  def workload
    s = "benchmark"
    100.times do |i|
      s += i.to_s
      s = s.reverse
      s = s.gsub("a", "A")
      s.index("b")
    end
    s.length
  end

  def run_once(iterations)
    GC.start
    t0 = Process.clock_gettime(Process::CLOCK_MONOTONIC)
    total_len = 0
    (iterations / 100).times do
      total_len += workload
    end
    t1 = Process.clock_gettime(Process::CLOCK_MONOTONIC)

    duration = t1 - t0
    ops_done = iterations

    {
      "time_s" => duration,
      "ops" => ops_done,
      "ops_per_sec" => (duration > 0 ? ops_done / duration : 0),
      "gc_stat_after" => GC.stat,
      "total_len" => total_len
    }
  end

  def run(runs = 5, iterations = nil)
    iterations ||= @ops_per_iter
    results = []
    runs.times { results << run_once(iterations) }

    times = results.map { |r| r["time_s"] }.sort
    ops = results.map { |r| r["ops_per_sec"] }.sort

    {
      "name" => @name,
      "runs" => runs,
      "median_time_sec" => times[times.length / 2],
      "median_ops_per_sec" => ops[ops.length / 2],
      "raw" => results
    }
  end
end

if __FILE__ == $0
  result = StringOpsTest.new.run
  File.open("string_ops_ruby.json", "w") { |f| f.write(JSON.pretty_generate(result)) }
  puts JSON.pretty_generate(result)
end
