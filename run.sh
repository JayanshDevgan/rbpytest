#!/bin/bash

RUNNER="run.c"
RUNNER_EXECUTABLE="exec"

COMPARE="compare.c"
COMPARE_EXECUTABLE="compare"

echo "Undergoes Compiling Process"
gcc $RUNNER -o $RUNNER_EXECUTABLE -Wall

if [ $? -eq 0 ]; then
    echo "Compilation successfull. Executing $RUNNER_EXECUTABLE..."
    ./$RUNNER_EXECUTABLE
fi

gcc $COMPARE -o $COMPARE_EXECUTABLE -Wall

if [ $? -eq 0 ]; then
    echo "Compilation successfull. Executing $COMPARE_EXECUTABLE..."
    ./$COMPARE_EXECUTABLE
else
    echo "Compilation failed."
fi