require "json"
require "tempfile"
require "time"

class FileIOTest
  attr_reader :name

  def initialize(size_mb = 50)
    @name = "File I/O"
    @size_mb = size_mb
    @test_file = File.join(Dir.tmpdir, "41e0a8c7d0.cgv")
  end

  def run_once
    data = ("X" * 1024 * 1024).b  # 1 MB block

    t0 = Process.clock_gettime(Process::CLOCK_MONOTONIC)
    File.open(@test_file, "wb") do |f|
      @size_mb.times { f.write(data) }
    end
    write_time = Process.clock_gettime(Process::CLOCK_MONOTONIC) - t0

    t1 = Process.clock_gettime(Process::CLOCK_MONOTONIC)
    File.open(@test_file, "rb") do |f|
      f.read(1024 * 1024) while f.read(1024 * 1024)
    end
    read_time = Process.clock_gettime(Process::CLOCK_MONOTONIC) - t1

    File.delete(@test_file) if File.exist?(@test_file)

    {
      "write_time_s" => write_time,
      "read_time_s" => read_time,
      "write_MBps" => @size_mb / write_time,
      "read_MBps" => @size_mb / read_time
    }
  end

  def run(runs = 3)
    results = Array.new(runs) { run_once }
    avg_write = results.sum { |r| r["write_MBps"] } / runs
    avg_read  = results.sum { |r| r["read_MBps"] } / runs

    {
      "name" => @name,
      "runs" => runs,
      "avg_write_MBps" => avg_write,
      "avg_read_MBps" => avg_read,
      "raw" => results
    }
  end
end

if __FILE__ == $0
  test = FileIOTest.new
  res = test.run
  File.write("results_ruby_fileio.json", JSON.pretty_generate(res))
  puts "#{res['name']}: Write=#{res['avg_write_MBps'].round(2)} MB/s | Read=#{res['avg_read_MBps'].round(2)} MB/s"
end
