import time
import json
import gc

class StringOpsTest:
    def __init__(self, ops_per_iter=500000):
        self.name = "StringOps"
        self.ops_per_iter = ops_per_iter

    def workload(self):
        s = "benchmark"
        for _ in range(100):
            s += str(_)
            s = s[::-1]
            s = s.replace("a", "A")
            s.find("b")
        return len(s)

    def run_once(self, iterations):
        gc.collect()
        start = time.perf_counter()
        total_len = 0
        for _ in range(iterations // 100):
            total_len += self.workload()
        end = time.perf_counter()

        duration = end - start
        ops_done = iterations
        return {
            "time_s": duration,
            "ops": ops_done,
            "ops_per_sec": ops_done / duration if duration > 0 else 0,
            "gc_stat_after": gc.get_stats() if hasattr(gc, "get_stats") else None,
            "total_len": total_len
        }

    def run(self, runs=5, iterations=None):
        iterations = iterations or self.ops_per_iter
        results = [self.run_once(iterations) for _ in range(runs)]
        times = sorted(r["time_s"] for r in results)
        ops = sorted(r["ops_per_sec"] for r in results)

        return {
            "name": self.name,
            "runs": runs,
            "median_time_sec": times[len(times)//2],
            "median_ops_per_sec": ops[len(ops)//2],
            "raw": results
        }

if __name__ == "__main__":
    result = StringOpsTest().run()
    with open("string_ops_python.json", "w") as f:
        json.dump(result, f, indent=2)
    print(json.dumps(result, indent=2))
