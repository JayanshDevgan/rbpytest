import time, json, gc
from concurrent.futures import ThreadPoolExecutor

class ThreadingTestTest:
    name = "Threading / Concurrency"

    def __init__(self, threads=8, work_size=2_000_000, runs=3):
        self.threads = threads
        self.work_size = work_size
        self.runs = runs

    def cpu_bound_work(self, n):
        s = 0
        for i in range(n):
            s += (i * i) % 97
        return s

    def thread_task(self):
        start = time.perf_counter()
        self.cpu_bound_work(self.work_size // self.threads)
        end = time.perf_counter()
        return end - start

    def run_once(self):
        gc.collect()

        t0 = time.perf_counter()

        with ThreadPoolExecutor(max_workers=self.threads) as pool:
            results = list(pool.map(lambda _: self.thread_task(), range(self.threads)))

        t1 = time.perf_counter()

        total_time = t1 - t0
        avg_thread_time = sum(results) / self.threads
        ops_per_s = self.work_size / total_time if total_time > 0 else float("inf")

        return {
            "total_time_s": total_time,
            "avg_thread_time_s": avg_thread_time,
            "ops_per_s": ops_per_s
        }

    def run(self, runs=None, iterations=None):
        if runs is None:
            runs = self.runs

        results = [self.run_once() for _ in range(runs)]
        times = sorted(r["total_time_s"] for r in results)
        ops   = sorted(r["ops_per_s"] for r in results)
        avg_t = sorted(r["avg_thread_time_s"] for r in results)

        mid = len(times) // 2

        return {
            "name": self.name,
            "runs": runs,
            "threads": self.threads,
            "median_total_time_s": times[mid],
            "median_avg_thread_time_s": avg_t[mid],
            "median_ops_per_s": ops[mid],
            "raw": results
        }

if __name__ == "__main__":
    result = ThreadingTestTest().run()
    with open("results_python_threading.json", "w") as f:
        json.dump(result, f, indent=2)
    print(json.dumps(result, indent=2))
