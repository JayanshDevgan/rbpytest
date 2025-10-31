require "json"
require "tempfile"
require "time"

class FileIOTest
  attr_reader :name

  def initialize(size_mb = 50)
    @name = "File I/O"
    @size_mb = size_mb
    @min_free_mb = size_mb * 2
  end

  # Cross-platform free disk space
  def free_space_mb(dir)
    if Gem.win_platform?
      out = `wmic logicaldisk get caption,freespace /value`
      drive = dir[0].upcase

      out.split("\n").each do |line|
        if line.start_with?("Caption=#{drive}:")
          free = line.split("\n")[1].split("=")[1].to_i
          return free / (1024 * 1024)
        end
      end
      999_999
    else
      out = `df -m #{dir} 2>/dev/null`
      parts = out.split("\n")[1].split
      parts[3].to_i # free MB
    end
  rescue
    999_999
  end

  # Safe deletion for Windows handle issues
  def safe_delete(path)
    return unless File.exist?(path)

    5.times do
      begin
        File.delete(path)
        return true
      rescue Errno::EACCES
        sleep(0.05)
      end
    end

    File.delete(path) rescue nil
  end

  def run_once
    block = ("X" * 1024 * 1024).b

    # Tempfile we should NOT manually delete
    tempfile = Tempfile.new("cgv_test", Dir.tmpdir)
    @test_file = tempfile.path + "_data"  # <-- Use a separate manual file

    free_mb = free_space_mb(Dir.tmpdir)
    if free_mb < @min_free_mb
      raise "Insufficient disk space: need #{@min_free_mb}MB, got #{free_mb}MB"
    end

    begin
      # Write test file
      t0 = Process.clock_gettime(Process::CLOCK_MONOTONIC)
      File.open(@test_file, "wb") do |f|
        @size_mb.times { f.write(block) }
      end
      write_time = Process.clock_gettime(Process::CLOCK_MONOTONIC) - t0

      # Read test file
      t1 = Process.clock_gettime(Process::CLOCK_MONOTONIC)
      File.open(@test_file, "rb") do |f|
        f.read(1024 * 1024) while f.read(1024 * 1024)
      end
      read_time = Process.clock_gettime(Process::CLOCK_MONOTONIC) - t1

    ensure
      tempfile.close  # auto-deletes the temp file it created
      safe_delete(@test_file)
    end

    {
      "write_time_s" => write_time,
      "read_time_s"  => read_time,
      "write_MBps"   => @size_mb / write_time,
      "read_MBps"    => @size_mb / read_time
    }
  end

  def run(runs = 3, iterations = nil)
    results = Array.new(runs) { run_once }

    write_list = results.map { |r| r["write_MBps"] }.sort
    read_list  = results.map { |r| r["read_MBps"] }.sort
    mid = runs / 2

    {
      "name" => @name,
      "runs" => runs,
      "size_mb" => @size_mb,
      "median_write_MBps" => write_list[mid],
      "median_read_MBps"  => read_list[mid],
      "raw" => results
    }
  end
end

FileIoTest = FileIOTest

if __FILE__ == $0
  test = FileIOTest.new(ARGV[0] ? ARGV[0].to_i : 5)
  res = test.run
  File.write("results_ruby_fileio.json", JSON.pretty_generate(res))
  puts JSON.pretty_generate(res)
end
