import time
import random
import json
import gc
import os

class ListOpsTest:
    def __init__(self, ops_per_iter=1_000_000, name="ListOps"):
        self.name = name
        self.ops_per_iter = ops_per_iter

    def workload(self):
        lst = []

        # Append phase
        for i in range(5000):
            lst.append(i)

        # Random insertions
        for _ in range(500):
            idx = random.randint(0, len(lst))
            lst.insert(idx, random.randint(0, 100))

        # Random deletions
        for _ in range(500):
            if lst:
                idx = random.randint(0, len(lst) - 1)
                del lst[idx]

        # Access phase
        s = 0
        for _ in range(1000):
            s += lst[random.randint(0, len(lst) - 1)]

        return s

    def run_once(self, iterations):
        reps = max(1, iterations // 1000, 50)
        t0 = time.perf_counter()
        total = 0

        for _ in range(reps):
            total += self.workload()

        t1 = time.perf_counter()
        duration = t1 - t0
        ops_done = reps * 1000

        return {
            "time_s": duration,
            "ops": ops_done,
            "ops_per_sec": ops_done / (duration if duration > 0 else 1e-9),
            "acc": total,
            "gc_stat_after": gc.get_stats()[-1] if hasattr(gc, "get_stats") else None
        }

    def run(self, runs=None, iterations=None):
        iterations = iterations or self.ops_per_iter
        runs = runs or 5
        results = []

        for _ in range(runs):
            results.append(self.run_once(iterations))
            gc.collect()

        times = sorted(r["time_s"] for r in results)
        ops = sorted(r["ops_per_sec"] for r in results)
        median_time = times[len(times)//2]
        median_ops = ops[len(ops)//2]

        return {
            "name": self.name,
            "runs": runs,
            "median_time_s": median_time,
            "median_ops_per_sec": median_ops,
            "raw": results
        }

if __name__ == "__main__":
    test = ListOpsTest()
    result = test.run()
    with open("results_list_ops_python.json", "w") as f:
        json.dump(result, f, indent=2)
    print(f"{result['name']}: Median Time={result['median_time_s']:.4f}s | "
          f"Ops/sec={result['median_ops_per_sec']:.2f}")
