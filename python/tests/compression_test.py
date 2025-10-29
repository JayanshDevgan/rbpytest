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
        # Cap iterations to avoid CPU overload
        effective_iters = min(iterations, 100_000)
        start = time.perf_counter()

        for _ in range(effective_iters):
            compressed = zlib.compress(self.data)
            decompressed = zlib.decompress(compressed)
            if decompressed != self.data:
                raise ValueError("Data mismatch after decompression")

        end = time.perf_counter()
        time_s = end - start
        ops_per_sec = effective_iters / time_s if time_s > 0 else 0
        return {
            "time_s": time_s,
            "ops_per_sec": ops_per_sec,
            "iterations": effective_iters
        }

    def run(self, runs=5, iterations=None):
        if iterations is None:
            iterations = self.ops_per_iter

        results = []
        for _ in range(runs):
            results.append(self.run_once(iterations))
            gc.collect()

        times = sorted([r["time_s"] for r in results])
        ops = sorted([r["ops_per_sec"] for r in results])
        mid = len(times) // 2

        return {
            "name": self.name,
            "runs": runs,
            "median_time_s": times[mid],
            "median_ops_per_s": ops[mid],
            "raw": results
        }


if __name__ == "__main__":
    result = CompressionTestTest().run()
    with open("results_compression_test_python.json", "w") as f:
        json.dump(result, f, indent=4)
    print(json.dumps(result, indent=4))
