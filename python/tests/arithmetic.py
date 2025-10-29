import time
import tracemalloc
import math
import gc

class ArithmeticTest:
    name = "Arithmetic"

    def __init__(self, ops_per_iter=10_000_000):
        self.ops_per_iter = ops_per_iter

    def _workload(self, size=100):
        s_int = 0
        s_float = 0.0
        for i in range(1, size + 1):
            s_int += i * (i & 1)
            s_float += math.sin(i) * math.sqrt(i)
        return s_int, s_float

    def run_once(self, iterations):
        gc.collect()
        tracemalloc.start()
        t0 = time.perf_counter()

        reps = max(1, iterations // 100)
        acc_int = 0
        acc_float = 0.0
        for _ in range(reps):
            i, f = self._workload(100)
            acc_int += i
            acc_float += f

        t1 = time.perf_counter()
        current, peak = tracemalloc.get_traced_memory()
        tracemalloc.stop()

        duration = t1 - t0
        ops_done = reps * 100
        return {
            "time_s": duration,
            "ops": ops_done,
            "ops_per_sec": ops_done / duration if duration > 0 else float("inf"),
            "mem_current_bytes": current,
            "mem_peak_bytes": peak,
            "acc_int": acc_int,
            "acc_float": acc_float
        }

    def run(self, runs=5, iterations=None):
        if iterations is None:
            iterations = self.ops_per_iter
        results = [self.run_once(iterations) for _ in range(runs)]

        times = sorted(r["time_s"] for r in results)
        ops_per_sec = sorted(r["ops_per_sec"] for r in results)
        peaks = sorted(r["mem_peak_bytes"] for r in results)
        mid = len(results) // 2

        return {
            "name": self.name,
            "runs": runs,
            "median_time_sec": times[mid],
            "median_ops_per_sec": ops_per_sec[mid],
            "median_peak_mem_bytes": peaks[mid],
            "raw": results
        }
