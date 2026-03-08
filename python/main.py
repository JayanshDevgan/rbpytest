from tests import algorithmic_mix, arithmetic, compression, file_io, json_serialization, list_ops, logic_control, matrix_multiplication, memory_access, recursive_fib, serialization, sorting_benchmark, string_concat, string_ops, threading
import json
from pathlib import Path

if __name__ == "__main__":
    tests = [
        algorithmic_mix.AlgorithmicMixTest(),
        arithmetic.ArithmeticTest(),
        compression.CompressionTest(),
        file_io.FileIOTest(),
        json_serialization.JsonSerializationTest(),
        list_ops.ListOpsTest(),
        logic_control.LogicControlTest(),
        matrix_multiplication.MatrixMultiplicationTest(),
        memory_access.MemoryAccessTest(),
        recursive_fib.RecursiveFibTest(),
        serialization.SerializationTest(),
        sorting_benchmark.SortingBenchmarkTest(),
        string_concat.StringConcatTest(),
        string_ops.StringOpsTest(),
        threading.ThreadingTest()
    ]

    for test in tests:
        print(f"Running {test.name}...")
        result = test.run()
        className = test.name.replace(" ", "") + "Test"
        with open("r_py_" + className + ".json", "w") as f:
            json.dump(result, f, indent=2)