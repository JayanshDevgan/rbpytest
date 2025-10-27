import time, tracemalloc, random

class MemoryAccessTest:
    name = "MemoryAccess"

    def __init__(self, ops_per_iter=5_000_000):
        self.ops_per_iter = ops_per_iter

    def workload(self, size=10_000):
        arr = list(range(size))
        s = 0
        for v in arr:
            s += v
        indices = list(range(size))
        random.shuffle(indices)
        for i in indices:
            s -= arr[i]
        return s

    def run_once(self, iterations):
        reps = max(1, iterations // 10_000)
        tracemalloc.start()
        t0 = time.perf_counter()
        acc = 0
        for _ in range(reps):
            acc += self.workload(10_000)
        t1 = time.perf_counter()
        current, peak = tracemalloc.get_traced_memory()
        tracemalloc.stop()
        duration = t1 - t0
        ops_done = reps * 10_000
        return {
            "time_s": duration,
            "ops": ops_done,
            "ops_per_sec": ops_done / duration if duration > 0 else float("inf"),
            "mem_peak_bytes": peak,
            "acc": acc
        }

    def run(self, runs=5, iterations=None):
        if iterations is None:
            iterations = self.ops_per_iter
        results = [self.run_once(iterations) for _ in range(runs)]
        times = sorted(r["time_s"] for r in results)
        ops = sorted(r["ops_per_sec"] for r in results)
        peak_mem = sorted(r["mem_peak_bytes"] for r in results)
        mid = len(times) // 2
        return {
            "name": self.name,
            "runs": runs,
            "median_time_s": times[mid],
            "median_ops_per_sec": ops[mid],
            "median_peak_mem_bytes": peak_mem[mid],
            "raw": results
        }