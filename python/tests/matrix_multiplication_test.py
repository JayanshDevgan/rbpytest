import time
import random
import json
import os

class MatrixMultiplicationTestTest:
    def __init__(self, size=100, runs=5):
        self.name = "Matrix Multiplication"
        self.size = size
        self.runs = runs

    def matrix_multiply(self, a, b):
        n = len(a)
        result = [[0] * n for _ in range(n)]
        for i in range(n):
            for j in range(n):
                s = 0
                for k in range(n):
                    s += a[i][k] * b[k][j]
                result[i][j] = s
        return result

    def run_once(self):
        A = [[random.random() for _ in range(self.size)] for _ in range(self.size)]
        B = [[random.random() for _ in range(self.size)] for _ in range(self.size)]
        t0 = time.perf_counter()
        self.matrix_multiply(A, B)
        t1 = time.perf_counter()
        duration = t1 - t0
        ops = (self.size ** 3) / (duration if duration > 0 else 1e-9)
        return {"time_s": duration, "ops_per_sec": ops}

    def run(self, runs=None, iterations=None):
        # Keep backward compatibility with external test harness
        if runs is not None:
            self.runs = runs

        results = [self.run_once() for _ in range(self.runs)]
        times = sorted(r["time_s"] for r in results)
        ops = sorted(r["ops_per_sec"] for r in results)
        median_time = times[len(times)//2]
        median_ops = ops[len(ops)//2]
        return {
            "name": self.name,
            "runs": self.runs,
            "median_time_s": median_time,
            "median_ops_per_s": median_ops,
            "raw": results
        }

if __name__ == "__main__":
    result = MatrixMultiplicationTestTest().run()
    with open("results_matrix_multiplication_python.json", "w") as f:
        json.dump(result, f, indent=2)
    print(json.dumps(result, indent=2))
