import time, json, gc, tracemalloc

class SerializationTestTest:
    name = "Serialization"

    def __init__(self, ops_per_iter=100_000):
        self.ops_per_iter = ops_per_iter
        # Prepare sample data once to avoid skewed timing from setup cost
        self.sample_data = [
            {"id": i, "name": f"Object_{i}", "value": i * 0.12345, "flag": i % 2 == 0}
            for i in range(10_000)
        ]

    def workload(self):
        encoded = json.dumps(self.sample_data)
        decoded = json.loads(encoded)
        # Returning size processed to simulate measurable workload output
        return len(encoded) + len(decoded)

    def run_once(self, iterations):
        gc.collect()
        tracemalloc.start()
        t0 = time.perf_counter()

        total_size = 0
        for _ in range(iterations):
            total_size += self.workload()

        t1 = time.perf_counter()
        current, peak = tracemalloc.get_traced_memory()
        tracemalloc.stop()

        duration = t1 - t0
        ops_done = iterations

        return {
            "time_s": duration,
            "ops": ops_done,
            "ops_per_sec": ops_done / duration if duration > 0 else float("inf"),
            "mem_peak_bytes": peak,
            "size_processed": total_size
        }

    def run(self, runs=5, iterations=None):
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
            "raw": results
        }

if __name__ == "__main__":
    result = SerializationTestTest().run()
    print(json.dumps(result, indent=2))
