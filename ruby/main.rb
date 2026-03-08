#!/usr/bin/env ruby

require 'json'
require 'pathname'

# Load all test modules (adjust paths if needed)
require_relative 'tests/algorithmic_mix'
require_relative 'tests/arithmetic'
require_relative 'tests/compression'
require_relative 'tests/file_io'
require_relative 'tests/json_serialization'
require_relative 'tests/list_ops'
require_relative 'tests/logic_control'
require_relative 'tests/matrix_multiplication'
require_relative 'tests/memory_access'
require_relative 'tests/recursive_fib'
require_relative 'tests/serialization'
require_relative 'tests/sorting_benchmark'
require_relative 'tests/string_concat'
require_relative 'tests/string_ops'
require_relative 'tests/threading'

if __FILE__ == $0
  tests = [
    AlgorithmicMixTest.new,
    ArithmeticTest.new,
    CompressionTest.new,
    FileIOTest.new,
    JsonSerializationTest.new,
    ListOpsTest.new,
    LogicControlTest.new,
    MatrixMultiplicationTest.new,
    MemoryAccessTest.new,
    RecursiveFibTest.new,
    SerializationTest.new,
    SortingBenchmarkTest.new,
    StringConcatTest.new,
    StringOpsTest.new,
    ThreadingTest.new
  ]

  tests.each do |test|
    puts "Running #{test.name}..."
    result = test.run
    filename = "results/r_rb_#{test.name.delete(' ')}Test.json"
    File.write(filename, JSON.pretty_generate(result))
  end
end
