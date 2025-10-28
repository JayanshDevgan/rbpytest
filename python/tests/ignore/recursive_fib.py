import time, tracemalloc, json

class RecursiveFibonacciTest:
    name = "RecursiveFibonacci"

    def __init__(self, n=20):
        self.n = n

    def fib(self, x):
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

    def run(self, runs=3):
        results = [self.run_once() for _ in range(runs)]
        times = sorted(r["time_s"] for r in results)
        ops = sorted(r["ops_per_sec"] for r in results)
        peaks = sorted(r["mem_peak_bytes"] for r in results)
        median = len(times) // 2
        return {
            "name": self.name,
            "runs": runs,
            "median_time_sec": times[median],
            "median_ops_per_sec": ops[median],
            "median_peak_mem_bytes": peaks[median],
            "raw": results
        }

if __name__ == "__main__":
    test = RecursiveFibonacciTest(24)
    result = test.run()
    with open("results_python_recursive_fib.json", "w") as f:
        json.dump(result, f, indent=2)
