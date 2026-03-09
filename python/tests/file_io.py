import os
from pathlib import Path
import time
import json
import tempfile
import gc

class FileIOTest:
    def __init__(self, size_mb=50, name="FileIO"):
        self.name = name
        self.size_mb = size_mb
        self.test_file = os.path.join(tempfile.gettempdir(), "41e0a8c7d0.cgv")

    def run_once(self):
        data = ("X" * 1024 * 1024).encode("utf-8")  # 1 MB block

        # Write test
        t0 = time.perf_counter()
        with open(self.test_file, "wb") as f:
            for _ in range(self.size_mb):
                f.write(data)
        write_time = time.perf_counter() - t0

        # Read test
        t1 = time.perf_counter()
        with open(self.test_file, "rb") as f:
            while f.read(1024 * 1024):
                pass
        read_time = time.perf_counter() - t1

        try:
            os.remove(self.test_file)
        except OSError:
            pass

        return {
            "time_s": write_time + read_time,
            "ops": self.size_mb,
            "write_time_s": write_time,
            "read_time_s": read_time,
            "write_MBps": self.size_mb / write_time if write_time > 0 else 0,
            "read_MBps": self.size_mb / read_time if read_time > 0 else 0,
            "ops_per_sec": self.size_mb / (write_time + read_time)
        }

    def run(self, runs=None, iterations=None):
        if runs is None:
            runs = 3
        results = []
        for _ in range(runs):
            results.append(self.run_once())
            gc.collect()

        avg_write = sum(r["write_MBps"] for r in results) / runs
        avg_read = sum(r["read_MBps"] for r in results) / runs

        times = sorted(r["time_s"] for r in results)
        ops = sorted(r["ops_per_sec"] for r in results)
        mid = len(times) // 2

        return {
            "name": self.name,
            "runs": runs,
            "avg_write_MBps": avg_write,
            "avg_read_MBps": avg_read,
            "median_time_sec": times[mid],
            "median_ops_per_sec": ops[mid],
            "raw": results
        }