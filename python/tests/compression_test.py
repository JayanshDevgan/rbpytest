import time
import json
import zlib
import gc

class CompressionTestTest:
    def __init__(self, name="CompressionTest", ops_per_iter=1000):
        self.name = name
        self.ops_per_iter = ops_per_iter
        self.data = ("The quick brown fox jumps over the lazy dog. " * 100).encode()

    def run_once(self, iterations):
        start = time.time()
        for _ in range(iterations):
            compressed = zlib.compress(self.data)
            decompressed = zlib.decompress(compressed)
            assert decompressed == self.data
        end = time.time()

        time_s = end - start
        ops_per_sec = iterations / time_s if time_s > 0 else 0
        return {"time_s": time_s, "ops_per_sec": ops_per_sec}

    def run(self, runs=None, iterations=None):
        # Default values for compatibility with C runner
        if runs is None:
            runs = 5
        if iterations is None:
            iterations = self.ops_per_iter

        results = []
        for _ in range(runs):
            results.append(self.run_once(iterations))
            gc.collect()

        times = sorted([r["time_s"] for r in results])
        ops = sorted([r["ops_per_sec"] for r in results])

        return {
            "name": self.name,
            "runs": runs,
            "median_time_s": times[len(times)//2],
            "median_ops_per_s": ops[len(ops)//2],
            "raw": results
        }

if __name__ == "__main__":
    result = CompressionTestTest().run()
    with open("results_compression_test_python.json", "w") as f:
        json.dump(result, f, indent=4)
    print(json.dumps(result, indent=4))
