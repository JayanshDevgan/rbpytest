require 'json'
require 'zlib'
GC.enable

class CompressionTestTest
    def initialize(name = "CompressionTest")
        @name = name
        @ops_per_iter = 1000
        @data = ("The quick brown fox jumps over the lazy dog. " * 100).encode("UTF-8")
    end

    def run_once(iterations)
        start = Time.now
        iterations.times do
            compressed = Zlib::Deflate.deflate(@data)
            decompressed = Zlib::Inflate.inflate(compressed)
            raise "Data mismatch" unless decompressed == @data
        end
        elapsed = Time.now - start
        ops_per_sec = iterations / elapsed
        { "time_s" => elapsed, "ops_per_sec" => ops_per_sec }
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
            "median_ops_per_s" => ops[ops.length / 2],
            "raw" => results
        }
    end
end

if __FILE__ == $0
    result = CompressionTestTest.new.run
    puts JSON.pretty_generate(result)
end
