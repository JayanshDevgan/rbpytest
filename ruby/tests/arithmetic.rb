require "json"
require "time"

class ArithmeticTest
  attr_reader :name

  def initialize(ops_per_iter = 10_000_000)
    @name = "Arithmetic"
    @ops_per_iter = ops_per_iter
  end

  def workload
    s_int = 0
    s_float = 0.0
    (1..999).each do |i|
      s_int += i * (i & 1)
      s_float += Math.sin(i) * Math.sqrt(i)
    end
    [s_int, s_float]
  end

  def run_once(iterations)
    reps = [1, iterations / 1000].max

    t0 = Process.clock_gettime(Process::CLOCK_MONOTONIC)
    acc_int = 0
    acc_float = 0.0

    reps.times do
      i, f = workload
      acc_int += i
      acc_float += f
    end

    duration = Process.clock_gettime(Process::CLOCK_MONOTONIC) - t0
    ops_done = reps * 1000
    ops_per_sec = ops_done / (duration > 0 ? duration : 1e-9)

    {
      "time_s" => duration,
      "ops" => ops_done,
      "ops_per_sec" => ops_per_sec,
      "acc_int" => acc_int,
      "acc_float" => acc_float,
      "gc_stat_after" => GC.stat
    }
  rescue Interrupt
    puts "\n[!] Arithmetic test interrupted — exiting safely."
    exit
  end

  def run(runs = 5, iterations = nil)
    iterations ||= @ops_per_iter
    results = []

    runs.times do
      results << run_once(iterations)
      GC.start
    end

    times = results.map { |r| r["time_s"] }.compact.sort
    ops = results.map { |r| r["ops_per_sec"] }.compact.sort

    median_time = times[times.length / 2]
    median_ops = ops[ops.length / 2]

    {
      "name" => @name,
      "runs" => runs,
      "median_time_s" => median_time,
      "median_ops_per_sec" => median_ops,
      "raw" => results
    }
  end
end

if __FILE__ == $0
  begin
    test = ArithmeticTest.new
    result = test.run
    File.write("results_arithmetic_ruby.json", JSON.pretty_generate(result))
    puts JSON.pretty_generate(result)
  rescue Interrupt
    puts "\n[!] Benchmark manually interrupted — partial data not saved."
  end
end
