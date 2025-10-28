import random, time, json, tracemalloc, gc

class SortingBenchmarkTest:
    name = "SortingBenchmark"

    def __init__(self, n=10000, ops_per_iter=None):
        self.n = n
        self.ops_per_iter = ops_per_iter or n  # for consistency with other tests

    def workload(self):
        data = [random.randint(0, 1_000_000) for _ in range(self.n)]
        data.sort()
        return sum(data[:100])  # checksum for sanity

    def run_once(self):
        gc.collect()
        tracemalloc.start()
        t0 = time.perf_counter()

        checksum = self.workload()

        t1 = time.perf_counter()
        current, peak = tracemalloc.get_traced_memory()
        tracemalloc.stop()

        duration = t1 - t0
        # Estimate operations as n * log2(n)
        ops_done = int(self.n * (self.n.bit_length()))

        return {
            "time_s": duration,
            "ops": ops_done,
            "ops_per_sec": ops_done / duration if duration > 0 else float("inf"),
            "mem_peak_bytes": peak,
            "checksum": checksum
        }

    def run(self, runs=5):
        results = [self.run_once() for _ in range(runs)]
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
    result = SortingBenchmarkTest(10_000).run()
    with open("results_python_sorting_benchmark.json", "w") as f:
        json.dump(result, f, indent=2)
