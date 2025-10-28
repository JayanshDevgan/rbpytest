import json
import time
import random
import gc
import os

class JSONSerializationTest:
    def __init__(self, obj_size=5000, depth=3, runs=5, name="JSON Serialization"):
        self.name = name
        self.obj_size = obj_size
        self.depth = depth
        self.runs = runs

    def _generate_nested(self, level):
        if level == 0:
            return {
                "id": random.randint(1, 1_000_000),
                "value": random.random(),
                "active": random.choice([True, False]),
                "text": "x" * 50
            }
        else:
            return {
                f"child_{i}": self._generate_nested(level - 1)
                for i in range(self.obj_size // 10)
            }

    def run_once(self):
        # Generate nested JSON data
        data = [self._generate_nested(self.depth) for _ in range(20)]

        # Measure encode/decode performance
        t0 = time.perf_counter()
        s = json.dumps(data)
        mid = time.perf_counter()
        _ = json.loads(s)
        t1 = time.perf_counter()

        encode_t = mid - t0
        decode_t = t1 - mid
        total = t1 - t0
        ops = len(s) / total if total > 0 else 0

        return {
            "encode_s": encode_t,
            "decode_s": decode_t,
            "total_s": total,
            "ops_per_s": ops
        }

    def run(self, runs=None, iterations=None):
        # `iterations` unused but included for benchmark uniformity
        if runs is None:
            runs = self.runs

        results = []
        for _ in range(runs):
            results.append(self.run_once())
            gc.collect()

        totals = sorted(r["total_s"] for r in results)
        ops = sorted(r["ops_per_s"] for r in results)
        median_t = totals[len(totals)//2]
        median_ops = ops[len(ops)//2]

        return {
            "name": self.name,
            "runs": runs,
            "median_total_s": median_t,
            "median_ops_per_s": median_ops,
            "raw": results
        }

if __name__ == "__main__":
    os.makedirs("results", exist_ok=True)
    result = JSONSerializationTestTest().run()
    with open("results_json_serialization_python.json", "w") as f:
        json.dump(result, f, indent=2)
    print(f"{result['name']}: Median Time={result['median_total_s']:.4f}s | "
          f"Ops/sec={result['median_ops_per_s']:.2f}")
