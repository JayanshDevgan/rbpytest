require "json"
require "time"

class MatrixMultiplicationTestTest
  attr_reader :name

  def initialize(size = 100)
    @name = "MatrixMultiplication"
    @size = size
  end

  def matrix_multiply(a, b)
    n = a.length
    result = Array.new(n) { Array.new(n, 0.0) }

    (0...n).each do |i|
      (0...n).each do |j|
        sum = 0.0
        (0...n).each do |k|
          sum += a[i][k] * b[k][j]
        end
        result[i][j] = sum
      end
    end

    result
  end

  def run_once
    n = @size
    a = Array.new(n) { Array.new(n) { rand } }
    b = Array.new(n) { Array.new(n) { rand } }

    t0 = Process.clock_gettime(Process::CLOCK_MONOTONIC)
    matrix_multiply(a, b)
    t1 = Process.clock_gettime(Process::CLOCK_MONOTONIC)

    duration = t1 - t0
    ops_per_sec = (n ** 3) / (duration > 0 ? duration : 1e-9)

    {
      "time_s" => duration,
      "ops_per_sec" => ops_per_sec
    }
  end

  def run(runs = 5, iterations = nil)
    results = Array.new(runs) { run_once }

    times = results.map { |r| r["time_s"] }.sort
    ops   = results.map { |r| r["ops_per_sec"] }.sort

    mid = runs / 2

    {
      "name" => @name,
      "runs" => runs,
      "median_time_s" => times[mid],
      "median_ops_per_sec" => ops[mid],
      "raw" => results
    }
  end
end

MatrixMultiplicationTest = MatrixMultiplicationTestTest

if __FILE__ == $0
  result = MatrixMultiplicationTestTest.new.run
  File.write("results_matrix_multiplication_ruby.json", JSON.pretty_generate(result))
  puts JSON.pretty_generate(result)
end
