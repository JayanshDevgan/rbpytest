require "json"
require "time"

class StringConcatTest
  attr_reader :name

  def initialize(n = 500_000)
    @name = "StringConcat"
    @n = n
  end

  def concat_plus
    s = ""
    @n.times { s += "a" }
    s.length
  end

  def concat_join
    arr = Array.new(@n, "a")
    arr.join.length
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
  end

  def run(runs = 3)
    results = Array.new(runs) { run_once }
    total = results.map { |r| r["total_time_s"] }.sort
    plus = results.map { |r| r["plus_time_s"] }.sort
    join = results.map { |r| r["join_time_s"] }.sort
    median = runs / 2
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
  test = StringConcatTest.new(500_000)
  result = test.run
  File.write("results_ruby_string_concat.json", JSON.pretty_generate(result))
end
