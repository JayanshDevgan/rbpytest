import time, json, tracemalloc, gc

class StringConcatTest:
    name = "StringConcat"

    def __init__(self, n=500_000):
        self.n = n

    def concat_plus(self):
        s = ""
        for _ in range(self.n):
            s += "a"
        return len(s)

    def concat_join(self):
        return len("".join(["a"] * self.n))

    def run_once(self):
        gc.collect()
        tracemalloc.start()
        t0 = time.perf_counter()

        length_plus = self.concat_plus()
        t1 = time.perf_counter()

        length_join = self.concat_join()
        t2 = time.perf_counter()

        current, peak = tracemalloc.get_traced_memory()
        tracemalloc.stop()

        plus_time = t1 - t0
        join_time = t2 - t1
        total_time = t2 - t0

        return {
            "plus_time_s": plus_time,
            "join_time_s": join_time,
            "total_time_s": total_time,
            "mem_peak_bytes": peak,
            "length_plus": length_plus,
            "length_join": length_join,
            "ops_per_sec_plus": self.n / plus_time if plus_time > 0 else float("inf"),
            "ops_per_sec_join": self.n / join_time if join_time > 0 else float("inf")
        }

    def run(self, runs=3):
        results = [self.run_once() for _ in range(runs)]
        total_times = sorted(r["total_time_s"] for r in results)
        plus_times = sorted(r["plus_time_s"] for r in results)
        join_times = sorted(r["join_time_s"] for r in results)
        peaks = sorted(r["mem_peak_bytes"] for r in results)
        mid = len(results) // 2

        return {
            "name": self.name,
            "runs": runs,
            "median_total_time_s": total_times[mid],
            "median_plus_time_s": plus_times[mid],
            "median_join_time_s": join_times[mid],
            "median_peak_mem_bytes": peaks[mid],
            "raw": results
        }

if __name__ == "__main__":
    result = StringConcatTest(500_000).run()
