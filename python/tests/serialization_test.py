import time, json, gc, tracemalloc

class SerializationTestTest:
    name = "Serialization"

    def __init__(self, ops_per_iter=1000):
        self.ops_per_iter = ops_per_iter
        self.sample_data = [
            {
                "id": i,
                "name": f"Object_{i}",
                "nested": {"val": i * 0.12345, "flag": i % 2 == 0},
                "tags": [f"tag_{j}" for j in range(5)],
            }
            for i in range(1000)
        ]
        self.encoded = json.dumps(self.sample_data)

    def workload(self):
        decoded = json.loads(self.encoded)
        encoded = json.dumps(decoded)
        return len(encoded)

    def run_once(self, iterations):
        gc.collect()
        tracemalloc.start()
        t0 = time.perf_counter()

        total_size = 0
        for _ in range(iterations):
            total_size += self.workload()

        t1 = time.perf_counter()
        _, peak = tracemalloc.get_traced_memory()
        tracemalloc.stop()

        duration = t1 - t0
        return {
            "time_s": duration,
            "ops": iterations,
            "ops_per_sec": iterations / duration if duration > 0 else float("inf"),
            "mem_peak_bytes": peak,
            "size_processed": total_size,
        }

    def run(self, runs=3, iterations=None):
        if iterations is None:
            iterations = self.ops_per_iter

        results = [self.run_once(iterations) for _ in range(runs)]
        times = sorted(r["time_s"] for r in results)
        ops = sorted(r["ops_per_sec"] for r in results)
        peaks = sorted(r["mem_peak_bytes"] for r in results)
        mid = len(times) // 2

        return {
            "name": self.name,
            "runs": runs,
            "median_time_s": times[mid],
            "median_ops_per_sec": ops[mid],
            "median_peak_mem_bytes": peaks[mid],
            "raw": results,
        }

if __name__ == "__main__":
    result = SerializationTestTest(ops_per_iter=200).run(runs=5)
    print(json.dumps(result, indent=2))
