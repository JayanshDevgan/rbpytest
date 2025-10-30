require "json"
require "time"

class StringConcatTest
  attr_reader :name

  def initialize(n = 50_000)
    @name = "StringConcat"
    @n = n
  end

  def concat_plus
    s = ""
    @n.times { s += "a" }
    s.length
  end

  def concat_join
    Array.new(@n, "a").join.length
  end

  def run_once
    t0 = Process.clock_gettime(Process::CLOCK_MONOTONIC)
    len_plus = concat_plus
    t1 = Process.clock_gettime(Process::CLOCK_MONOTONIC)
    len_join = concat_join
    t2 = Process.clock_gettime(Process::CLOCK_MONOTONIC)
    {
      "plus_time_s" => t1 - t0,
      "join_time_s" => t2 - t1,
      "total_time_s" => t2 - t0,
      "length_plus" => len_plus,
      "length_join" => len_join
    }
  rescue Interrupt
    { "error" => "Interrupted during test" }
  end

  def run(runs = 3, _initialize = nil)
    results = Array.new(runs) { run_once }
    valid_results = results.reject { |r| r.key?("error") }

    if valid_results.empty?
      return { "name" => @name, "error" => "All runs interrupted" }
    end

    total = valid_results.map { |r| r["total_time_s"] }.sort
    plus = valid_results.map { |r| r["plus_time_s"] }.sort
    join = valid_results.map { |r| r["join_time_s"] }.sort
    median = valid_results.size / 2

    {
      "name" => @name,
      "runs" => runs,
      "median_total_time_s" => total[median],
      "median_plus_time_s" => plus[median],
      "median_join_time_s" => join[median],
      "raw" => results
    }
  end
end

if __FILE__ == $0
  test = StringConcatTest.new(50_000)
  result = test.run
  timestamp = Time.now.strftime('%Y%m%d_%H%M%S')
  filename = "results_ruby_string_concat_#{timestamp}.json"
  File.write(filename, JSON.pretty_generate(result))
  puts "Results saved to #{filename}"
  puts JSON.pretty_generate(result)
end