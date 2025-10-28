require "json"

class SerializationTest
  attr_reader :name

  def initialize(ops_per_iter = 100_000)
    @name = "Serialization"
    @ops_per_iter = ops_per_iter
    @sample_data = Array.new(10_000) do |i|
      { id: i, name: "Object_#{i}", value: i * 0.12345, flag: i.even? }
    end
  end

  def workload
    encoded = JSON.generate(@sample_data)
    decoded = JSON.parse(encoded)
    encoded.bytesize + decoded.size
  end

  def run_once(iterations)
    GC.start
    t0 = Process.clock_gettime(Process::CLOCK_MONOTONIC)
    total_size = 0
    iterations.times do
      total_size += workload
    end
    t1 = Process.clock_gettime(Process::CLOCK_MONOTONIC)
    duration = t1 - t0
    ops_done = iterations
    {
      "time_s" => duration,
      "ops" => ops_done,
      "ops_per_sec" => ops_done / (duration > 0 ? duration : 1e-9),
      "size_processed" => total_size,
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
  require "json"
  puts JSON.pretty_generate(SerializationTest.new.run)
end
