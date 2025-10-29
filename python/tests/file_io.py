import os
import time
import json
import tempfile
import gc

class FileIoTest:
    def __init__(self, size_mb=50, name="FileIOTest"):
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
            "write_time_s": write_time,
            "read_time_s": read_time,
            "write_MBps": self.size_mb / write_time if write_time > 0 else 0,
            "read_MBps": self.size_mb / read_time if read_time > 0 else 0
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

        return {
            "name": self.name,
            "runs": runs,
            "avg_write_MBps": avg_write,
            "avg_read_MBps": avg_read,
            "raw": results
        }

if __name__ == "__main__":
    res = FileIoTest().run()
    with open("results_file_io_test_python.json", "w") as f:
        json.dump(res, f, indent=2)
    print(f"{res['name']}: Write={res['avg_write_MBps']:.2f} MB/s | Read={res['avg_read_MBps']:.2f} MB/s")
