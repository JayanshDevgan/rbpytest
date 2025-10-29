import time, tracemalloc, json

class RecursiveFibTest:
    name = "RecursiveFibonacci"

    def __init__(self, n=24):
        self.n = n

    def fib(self, x):
        # iterative fallback for large n
        if x > 40:
            a, b = 0, 1
            for _ in range(x):
                a, b = b, a + b
            return a
        if x < 2:
            return x
        return self.fib(x - 1) + self.fib(x - 2)

    def run_once(self):
        tracemalloc.start()
        t0 = time.perf_counter()
        result = self.fib(self.n)
        t1 = time.perf_counter()
        current, peak = tracemalloc.get_traced_memory()
        tracemalloc.stop()
        duration = t1 - t0
        return {
            "time_s": duration,
            "result": result,
            "mem_peak_bytes": peak,
            "ops_per_sec": 1.0 / duration if duration > 0 else float('inf')
        }

    def run(self, runs=None, iterations=None):
        if runs is None:
            runs = 3
        results = [self.run_once() for _ in range(runs)]
        times = sorted(r["time_s"] for r in results)
        ops = sorted(r["ops_per_sec"] for r in results)
        peaks = sorted(r["mem_peak_bytes"] for r in results)
        mid = len(times) // 2
        return {
            "name": self.name,
            "runs": runs,
            "median_time_sec": times[mid],
            "median_ops_per_sec": ops[mid],
            "median_peak_mem_bytes": peaks[mid],
            "raw": results
        }

if __name__ == "__main__":
    test = RecursiveFibTest(24)
    result = test.run()
    with open("results_python_recursive_fib.json", "w") as f:
        json.dump(result, f, indent=2)
    print(json.dumps(result, indent=2))
