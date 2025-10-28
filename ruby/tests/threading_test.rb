require "json"
require "time"

class ThreadingTest
  attr_reader :name

  def initialize(threads = 8, work_size = 2_000_000)
    @name = "Threading / Concurrency"
    @threads = threads
    @work_size = work_size
  end

  def cpu_bound_work(n)
    s = 0
    n.times do |i|
      s += (i * i) % 97
    end
    s
  end

  def run
    results = Array.new(@threads, 0.0)
    threads = []

    t0 = Process.clock_gettime(Process::CLOCK_MONOTONIC)

    @threads.times do |i|
      threads << Thread.new do
        t_start = Process.clock_gettime(Process::CLOCK_MONOTONIC)
        cpu_bound_work(@work_size / @threads)
        t_end = Process.clock_gettime(Process::CLOCK_MONOTONIC)
        results[i] = t_end - t_start
      end
    end

    threads.each(&:join)

    t1 = Process.clock_gettime(Process::CLOCK_MONOTONIC)
    total_time = t1 - t0
    avg_thread_time = results.sum / @threads
    ops_per_s = @work_size / (total_time > 0 ? total_time : 1e-9)

    {
      "name" => @name,
      "threads" => @threads,
      "total_time_s" => total_time,
      "avg_thread_time_s" => avg_thread_time,
      "ops_per_s" => ops_per_s
    }
  end
end

if __FILE__ == $0
  test = ThreadingTest.new
  result = test.run
  File.write("results_threading_ruby.json", JSON.pretty_generate(result))
  puts JSON.pretty_generate(result)
end
