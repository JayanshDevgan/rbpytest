@echo off
set RUNNER=run.c
set RUNNER_EXECUTABLE=exec.exe

set COMPARE=compare.c
set COMPARE_EXECUTABLE=compare.exe

echo Undergoes Compiling Process

g++ %RUNNER% -o %RUNNER_EXECUTABLE% -Wall

if %errorlevel% equ 0 (
    echo Compilation successful. Executing %RUNNER_EXECUTABLE%...
    %RUNNER_EXECUTABLE%
) else (
    echo Compilation failed for %RUNNER%
    exit /b
)

g++ %COMPARE% -o %COMPARE_EXECUTABLE% -Wall

if %errorlevel% equ 0 (
    echo Compilation successful. Executing %COMPARE_EXECUTABLE%...
    %COMPARE_EXECUTABLE%
) else (
    echo Compilation failed for %COMPARE%
)

pause