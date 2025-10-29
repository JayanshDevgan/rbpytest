import time, math, random, json, os

class AlgorithmicMixTestTest:
    def __init__(self, size=5000, depth=8, runs=5):
        self.name = "Algorithmic Mix"
        self.size = size
        self.depth = depth
        self.runs = runs

    def _recursive_fib(self, n):
        if n < 2:
            return n
        return self._recursive_fib(n - 1) + self._recursive_fib(n - 2)

    def _sort_and_search(self, arr):
        arr.sort()
        target = arr[len(arr)//2]
        return arr.index(target)

    def _io_cycle(self, data):
        fname = "temp_mix_test.tmp"
        with open(fname, "w") as f:
            json.dump(data, f)
        with open(fname, "r") as f:
            return json.load(f)
        os.remove(fname)

    def run_once(self):
        numbers = [random.randint(1, 100000) for _ in range(min(self.size, 5000))]  # ✅ Cap to safe size

        t0 = time.perf_counter()
        math_sum = sum(math.sin(i) * math.sqrt(i % 100 + 1) for i in range(1, 500))
        fib_val = self._recursive_fib(10)
        idx = self._sort_and_search(numbers)
        _ = self._io_cycle({"sum": math_sum, "fib": fib_val, "idx": idx, "nums": numbers[:50]})
        t1 = time.perf_counter()

        duration = t1 - t0
        return {"duration_s": duration, "ops_per_s": 1 / duration if duration > 0 else 0}

    def run(self, runs=None, iterations=None):
        if runs is not None:
            self.runs = runs
        if iterations is not None:
            self.size = min(iterations, 5000)  # ✅ Avoid huge freeze

        results = [self.run_once() for _ in range(self.runs)]
        times = sorted(r["duration_s"] for r in results)
        ops = sorted(r["ops_per_s"] for r in results)
        return {
            "name": self.name,
            "runs": self.runs,
            "median_time_s": times[len(times)//2],
            "median_ops_per_s": ops[len(ops)//2],
            "raw": results
        }

if __name__ == "__main__":
    result = AlgorithmicMixTestTest().run()
    with open("results_algorithmic_mix_python.json", "w") as f:
        json.dump(result, f, indent=2)
    print(json.dumps(result, indent=2))
