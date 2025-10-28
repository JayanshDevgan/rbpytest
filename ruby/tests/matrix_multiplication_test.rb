require 'json'

def matrix_multiply(a, b)
  n = a.length
  result = Array.new(n) { Array.new(n, 0.0) }
  for i in 0...n
    for j in 0...n
      sum = 0.0
      for k in 0...n
        sum += a[i][k] * b[k][j]
      end
      result[i][j] = sum
    end
  end
  result
end

def run_matrix_test(size = 100, iterations = 5)
  total_time = 0.0
  iterations.times do
    a = Array.new(size) { Array.new(size) { rand } }
    b = Array.new(size) { Array.new(size) { rand } }
    start = Process.clock_gettime(Process::CLOCK_MONOTONIC)
    matrix_multiply(a, b)
    finish = Process.clock_gettime(Process::CLOCK_MONOTONIC)
    total_time += (finish - start)
  end
  avg_time = total_time / iterations
  ops_per_sec = (size ** 3) / avg_time
  { "test_name" => "Matrix Multiplication Test", "median_ops_per_sec" => ops_per_sec }
end

result = run_matrix_test
puts JSON.generate(result)
