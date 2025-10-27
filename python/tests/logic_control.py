import time, json, gc

class LogicControlTest:
    def __init__(self, ops_per_iter=10_000_000):
        self.name = "LogicControl"
        self.ops_per_iter = ops_per_iter

    def workload(self):
        acc = 0
        for i in range(1, 500):
            if i % 15 == 0:
                acc += i * 2
            elif i % 5 == 0:
                acc -= i
            elif i % 3 == 0:
                acc += i // 2
            else:
                acc += (i & 1)
        return acc

    def run_once(self, iterations):
        reps = max(1, iterations // 1000)
        t0 = time.perf_counter()
        acc = 0
        for _ in range(reps):
            acc += self.workload()
        t1 = time.perf_counter()
        duration = t1 - t0
        ops_done = reps * 1000
        return {
            "time_s": duration,
            "ops": ops_done,
            "ops_per_sec": ops_done / (duration if duration > 0 else 1e-9),
            "acc": acc,
            "gc_stat_after": gc.get_stats()[-1] if hasattr(gc, "get_stats") else None
        }

    def run(self, runs=5, iterations=None):
        iterations = iterations or self.ops_per_iter
        results = []
        for _ in range(runs):
            results.append(self.run_once(iterations))
            gc.collect()
        times = sorted(r["time_s"] for r in results)
        ops = sorted(r["ops_per_sec"] for r in results)
        return {
            "name": self.name,
            "runs": runs,
            "median_time_s": times[len(times)//2],
            "median_ops_per_sec": ops[len(ops)//2],
            "raw": results
        }

if __name__ == "__main__":
    test = LogicControlTest()
    result = test.run()
    print(json.dumps(result, indent=2))
