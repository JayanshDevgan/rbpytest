require "json"
require "time"
require "securerandom"

class JSONSerializationTest
  attr_reader :name

  def initialize(obj_size = 5000, depth = 3, runs = 5)
    @name = "JSON Serialization"
    @obj_size = obj_size
    @depth = depth
    @runs = runs
  end

  def generate_nested(level)
    if level == 0
      {
        "id" => rand(1..1_000_000),
        "value" => rand,
        "active" => [true, false].sample,
        "text" => "x" * 50
      }
    else
      Hash[(0...@obj_size / 10).map { |i| ["child_#{i}", generate_nested(level - 1)] }]
    end
  end

  def run_once
    data = Array.new(20) { generate_nested(@depth) }

    t0 = Process.clock_gettime(Process::CLOCK_MONOTONIC)
    json_str = JSON.dump(data)
    t_mid = Process.clock_gettime(Process::CLOCK_MONOTONIC)
    JSON.parse(json_str)
    t1 = Process.clock_gettime(Process::CLOCK_MONOTONIC)

    encode_t = t_mid - t0
    decode_t = t1 - t_mid
    total = t1 - t0
    ops = json_str.size / (total > 0 ? total : 1e-9)

    {
      "encode_s" => encode_t,
      "decode_s" => decode_t,
      "total_s" => total,
      "ops_per_s" => ops
    }
  end

  def run
    results = Array.new(@runs) { run_once }
    totals = results.map { |r| r["total_s"] }.sort
    ops = results.map { |r| r["ops_per_s"] }.sort
    median_t = totals[totals.size / 2]
    median_ops = ops[ops.size / 2]

    {
      "name" => @name,
      "runs" => @runs,
      "median_total_s" => median_t,
      "median_ops_per_s" => median_ops,
      "raw" => results
    }
  end
end

if __FILE__ == $0
  result = JSONSerializationTest.new.run
  File.write("results_json_serialization_ruby.json", JSON.pretty_generate(result))
  puts JSON.pretty_generate(result)
end
