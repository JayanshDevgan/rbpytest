require "json"
require "time"

class ThreadingTestTest
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

  def single_run
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
      "total_time_s" => total_time,
      "avg_thread_time_s" => avg_thread_time,
      "ops_per_s" => ops_per_s
    }
  end

  def run(runs = 3, _initialize = nil)
    results = Array.new(runs) { single_run }
    valid_results = results.reject { |r| r.nil? || r.empty? }

    if valid_results.empty?
      return { "name" => @name, "error" => "All runs failed" }
    end

    total_times = valid_results.map { |r| r["total_time_s"] }.sort
    avg_thread_times = valid_results.map { |r| r["avg_thread_time_s"] }.sort
    ops_per_ss = valid_results.map { |r| r["ops_per_s"] }.sort
    median_idx = valid_results.size / 2

    {
      "name" => @name,
      "threads" => @threads,
      "runs" => runs,
      "median_total_time_s" => total_times[median_idx],
      "median_avg_thread_time_s" => avg_thread_times[median_idx],
      "median_ops_per_s" => ops_per_ss[median_idx],
      "raw" => results
    }
  rescue Interrupt
    { "name" => @name, "error" => "Interrupted during test" }
  end
end

if __FILE__ == $0
  test = ThreadingTestTest.new
  result = test.run
  timestamp = Time.now.strftime('%Y%m%d_%H%M%S')
  filename = "results_threading_ruby_#{timestamp}.json"
  File.write(filename, JSON.pretty_generate(result))
  puts "Results saved to #{filename}"
  puts JSON.pretty_generate(result)
end