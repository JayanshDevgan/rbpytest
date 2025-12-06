import time, json, tracemalloc, gc, math

class ArithmeticTest:
    name = "Arithmetic"

    def __init__(self, n=10_000_000):
        self.n = n

    def workload(self):
        s_int = 0
        s_float = 0.0
        for i in range(1, self.n + 1):
            s_int += i * (i & 1)
            s_float += math.sin(i) * math.sqrt(i)
        return s_int, s_float

    def run_once(self):
        gc.collect()
        tracemalloc.start()
        t0 = time.perf_counter()

        s_int, s_float = self.workload()
        t1 = time.perf_counter()

        current, peak = tracemalloc.get_traced_memory()
        tracemalloc.stop()

        duration = t1 - t0

        return {
            "time_s": duration,
            "ops": self.n,
            "ops_per_sec": self.n / duration if duration > 0 else float("inf"),
            "mem_peak_bytes": peak,
            "acc_int": s_int,
            "acc_float": s_float
        }

    def run(self, runs=5, iterations=None):
        results = [self.run_once() for _ in range(runs)]

        times = sorted(r["time_s"] for r in results)
        ops = sorted(r["ops_per_sec"] for r in results)
        peaks = sorted(r["mem_peak_bytes"] for r in results)
        mid = len(results) // 2

        return {
            "name": self.name,
            "runs": runs,
            "median_time_s": times[mid],
            "median_ops_per_sec": ops[mid],
            "median_peak_mem_bytes": peaks[mid],
            "raw": results
        }

if __name__ == "__main__":
    result = ArithmeticTest(10_000_000).run()
    with open("results_arithmetic_python.json", "w") as f:
        json.dump(result, f, indent=2)
    print(json.dumps(result, indent=2))
