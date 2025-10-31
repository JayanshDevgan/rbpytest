/*
 runner_mt.c
 Multithreaded test orchestrator (POSIX pthreads and Windows threads supported).
 - Scans python/tests/*.py and ruby/tests/*.rb
 - For each test spawns two threads: run python and run ruby commands concurrently
 - Captures stdout->json files and prints summary
*/

#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <sys/stat.h>

#ifdef _WIN32
#include <windows.h>
#define PATH_SEP '\\'
#else
#include <pthread.h>
#include <unistd.h>
#define PATH_SEP '/'
#endif

/* Colors */
#define COLOR_RESET "\033[0m"
#define COLOR_GREEN "\033[32m"
#define COLOR_RED "\033[31m"
#define COLOR_YELLOW "\033[33m"
#define COLOR_BOLD "\033[1m"

#define MAX_TESTS 256
#define MAX_NAME 128

/* Config */
#define DEFAULT_RUNS 5
#define DEFAULT_OPS 10000000LL

/* forward declarations */
int list_files_shell(const char *pattern, char names[][MAX_NAME], int max_names);
int run_and_capture(const char *cmd, const char *output_file);
double extract_ops(const char *filename);

/* ---- Thread-safety primitives ---- */
#ifdef _WIN32
static CRITICAL_SECTION print_mutex;
static void init_mutex() { InitializeCriticalSection(&print_mutex); }
static void lock_mutex() { EnterCriticalSection(&print_mutex); }
static void unlock_mutex() { LeaveCriticalSection(&print_mutex); }
static void destroy_mutex() { DeleteCriticalSection(&print_mutex); }
#else
static pthread_mutex_t print_mutex = PTHREAD_MUTEX_INITIALIZER;
static void init_mutex() { /* already initialized */ }
static void lock_mutex() { pthread_mutex_lock(&print_mutex); }
static void unlock_mutex() { pthread_mutex_unlock(&print_mutex); }
static void destroy_mutex() { pthread_mutex_destroy(&print_mutex); }
#endif

/* helper: get basename without extension from a full path */
void extract_basename_noext(const char *path, char *out, size_t outsz)
{
    const char *p = path;
    const char *last_sep = NULL;
    while (*p)
    {
        if (*p == '/' || *p == '\\')
            last_sep = p;
        p++;
    }
    const char *name = last_sep ? last_sep + 1 : path;
    strncpy(out, name, outsz - 1);
    out[outsz - 1] = '\0';
    char *dot = strrchr(out, '.');
    if (dot)
        *dot = '\0';
}

/* snake_case -> CamelCaseTest */
void snake_to_camel_test(const char *snake, char *out, size_t outsz)
{
    size_t j = 0;
    int cap_next = 1;
    for (size_t i = 0; snake[i] != '\0' && j + 1 < outsz; ++i)
    {
        char c = snake[i];
        if (c == '_' || c == '-')
        {
            cap_next = 1;
            continue;
        }
        if (cap_next)
        {
            if (c >= 'a' && c <= 'z')
                c = c - 'a' + 'A';
            cap_next = 0;
        }
        out[j++] = c;
    }
    const char *suffix = "Test";
    size_t sufflen = strlen(suffix);
    if (j + sufflen + 1 < outsz)
    {
        strcpy(&out[j], suffix);
        j += sufflen;
    }
    out[j] = '\0';
}

/* create directory if missing */
void ensure_dir(const char *path)
{
    struct stat st;
    if (stat(path, &st) != 0)
    {
#ifdef _WIN32
        char cmd[512];
        snprintf(cmd, sizeof(cmd), "mkdir \"%s\"", path);
        system(cmd);
#else
        char cmd[512];
        snprintf(cmd, sizeof(cmd), "mkdir -p '%s'", path);
        system(cmd);
#endif
    }
}

/* run_and_capture: runs cmd and redirects stdout/stderr to output_file */
int run_and_capture(const char *cmd, const char *output_file)
{
#ifdef _WIN32
    char fullcmd[4096];
    snprintf(fullcmd, sizeof(fullcmd), "cmd /C \"%s > \"%s\" 2>&1\"", cmd, output_file);
    return system(fullcmd);
#else
    char fullcmd[4096];
    snprintf(fullcmd, sizeof(fullcmd), "%s > '%s' 2>&1", cmd, output_file);
    return system(fullcmd);
#endif
}

/* extract median_ops_per_sec heuristic */
double extract_ops(const char *filename)
{
    FILE *f = fopen(filename, "r");
    if (!f)
        return -1.0;
    char line[2048];
    double val = -1.0;
    while (fgets(line, sizeof(line), f))
    {
        char *pos = strstr(line, "\"median_ops_per_sec\"");
        if (!pos)
            pos = strstr(line, "'median_ops_per_sec'");
        if (pos)
        {
            char *colon = strchr(pos, ':');
            if (!colon)
                continue;
            colon++;
            while (*colon && (*colon == ' ' || *colon == '\"' || *colon == '\'' || *colon == '\t' || *colon == ','))
                colon++;
            val = atof(colon);
            break;
        }
    }
    fclose(f);
    return val;
}

/* list files using shell (ls or dir). pattern like "python/tests/*.py" */
int list_files_shell(const char *pattern, char names[][MAX_NAME], int max_names)
{
    char cmd[512];
#ifdef _WIN32
    snprintf(cmd, sizeof(cmd), "dir /b %s 2>nul", pattern);
#else
    snprintf(cmd, sizeof(cmd), "ls %s 2>/dev/null", pattern);
#endif
    FILE *fp = popen(cmd, "r");
    if (!fp)
        return 0;
    char buf[512];
    int count = 0;
    while (fgets(buf, sizeof(buf), fp) && count < max_names)
    {
        buf[strcspn(buf, "\r\n")] = 0;
        if (strlen(buf) == 0)
            continue;
        if (strstr(buf, "__pycache__"))
            continue;
        char base[MAX_NAME];
        extract_basename_noext(buf, base, sizeof(base));
        if (strcmp(base, "runner") == 0)
            continue;
        strncpy(names[count], base, MAX_NAME - 1);
        names[count][MAX_NAME - 1] = '\0';
        count++;
    }
    pclose(fp);
    return count;
}

/* per-job struct passed to thread */
typedef struct
{
    char testname[MAX_NAME];
    char lang[8]; /* "python" or "ruby" */
    long runs;
    long long ops;
    char outpath[512];
} job_t;

/* thread worker: runs one command (python or ruby) and logs status */
#ifdef _WIN32
DWORD WINAPI worker_thread(LPVOID arg)
{
    job_t *job = (job_t *)arg;
    char classname[256];
    snake_to_camel_test(job->testname, classname, sizeof(classname));

    char cmd[2048];
#ifdef _WIN32
    const char *pybin = "python";
#else
    const char *pybin = "python3";
#endif

    if (strcmp(job->lang, "python") == 0)
    {
        snprintf(cmd, sizeof(cmd),
                 "%s -c \"import json, sys; sys.path.insert(0, 'python/tests'); from %s import %s; res = %s(%lld).run(runs=%ld, iterations=%lld); print(json.dumps(res))\"",
                 pybin, job->testname, classname, classname, job->ops, job->runs, job->ops);
    }
    else
    {
        snprintf(cmd, sizeof(cmd),
                 "ruby -r json -I ruby/tests -e \"require '%s'; t = %s.new; res = t.run(%ld, %lld); puts JSON.generate(res)\"",
                 job->testname, classname, job->runs, job->ops);
    }

    lock_mutex();
    printf("[START %s for %s]\n", job->lang, job->testname);
    unlock_mutex();

    int rc = run_and_capture(cmd, job->outpath);

    lock_mutex();
    if (rc == 0)
    {
        printf("[DONE  %s for %s] -> %s\n", job->lang, job->testname, job->outpath);
    }
    else
    {
        printf("[FAIL  %s for %s] (code %d) -> %s\n", job->lang, job->testname, rc, job->outpath);
    }
    unlock_mutex();

    free(job);
    return 0;
}
#else
void *worker_thread(void *arg)
{
    job_t *job = (job_t *)arg;
    char classname[256];
    snake_to_camel_test(job->testname, classname, sizeof(classname));

    char cmd[2048];
    const char *pybin = "python3";

    if (strcmp(job->lang, "python") == 0)
    {
        snprintf(cmd, sizeof(cmd),
                 "%s -c \"import json, sys; sys.path.insert(0, 'python/tests'); from %s import %s; res = %s(%lld).run(runs=%ld, iterations=%lld); print(json.dumps(res))\"",
                 pybin, job->testname, classname, classname, job->ops, job->runs, job->ops);
    }
    else
    {
        snprintf(cmd, sizeof(cmd),
                 "ruby -r json -I ruby/tests -e \"require '%s'; t = %s.new(%lld); res = t.run(%ld, %lld); puts JSON.generate(res)\"",
                 job->testname, classname, job->ops, job->runs, job->ops);
    }

    lock_mutex();
    printf("[START %s for %s]\n", job->lang, job->testname);
    unlock_mutex();

    int rc = run_and_capture(cmd, job->outpath);

    lock_mutex();
    if (rc == 0)
    {
        printf("[DONE  %s for %s] -> %s\n", job->lang, job->testname, job->outpath);
    }
    else
    {
        printf("[FAIL  %s for %s] (code %d) -> %s\n", job->lang, job->testname, rc, job->outpath);
    }
    unlock_mutex();

    free(job);
    return NULL;
}
#endif

/* print header and row helpers */
void print_table_header()
{
    printf("\n" COLOR_BOLD "=============================================================\n" COLOR_RESET);
    printf("%-20s | %-15s | %-15s | Winner\n", "Category", "Python (ops/s)", "Ruby (ops/s)");
    printf("=============================================================\n");
}

void print_comparison_row(const char *name, double pyops, double rbops)
{
    char pybuf[32], rbbuf[32];
    if (pyops < 0)
        strcpy(pybuf, "Missing");
    else
        snprintf(pybuf, sizeof(pybuf), "%.0f", pyops);

    if (rbops < 0)
        strcpy(rbbuf, "Missing");
    else
        snprintf(rbbuf, sizeof(rbbuf), "%.0f", rbops);

    if (pyops < 0 && rbops < 0)
    {
        printf("%-20s | %-15s | %-15s | %sNo Results%s\n", name, "N/A", "N/A", COLOR_YELLOW, COLOR_RESET);
        return;
    }
    else if (pyops < 0)
    {
        printf("%-20s | %-15s | %s%-15s%s | %sRuby Only%s\n", name, "Missing", COLOR_GREEN, rbbuf, COLOR_RESET, COLOR_GREEN, COLOR_RESET);
        return;
    }
    else if (rbops < 0)
    {
        printf("%-20s | %s%-15s%s | %-15s | %sPython Only%s\n", name, COLOR_GREEN, pybuf, COLOR_RESET, "Missing", COLOR_GREEN, COLOR_RESET);
        return;
    }

    double diff = 0.0;
    const char *winner;
    char pycol[64], rbcol[64];

    if (pyops > rbops)
        diff = ((pyops - rbops) / rbops) * 100.0;
    else
        diff = ((rbops - pyops) / pyops) * 100.0;

    if (pyops / rbops >= 1.2)
    {
        snprintf(pycol, sizeof(pycol), "%s%s%s", COLOR_GREEN, pybuf, COLOR_RESET);
        snprintf(rbcol, sizeof(rbcol), "%s%s%s", COLOR_RED, rbbuf, COLOR_RESET);
        winner = COLOR_GREEN "Python" COLOR_RESET;
    }
    else if (rbops / pyops >= 1.2)
    {
        snprintf(pycol, sizeof(pycol), "%s%s%s", COLOR_RED, pybuf, COLOR_RESET);
        snprintf(rbcol, sizeof(rbcol), "%s%s%s", COLOR_GREEN, rbbuf, COLOR_RESET);
        winner = COLOR_GREEN "Ruby" COLOR_RESET;
    }
    else
    {
        snprintf(pycol, sizeof(pycol), "%s%s%s", COLOR_YELLOW, pybuf, COLOR_RESET);
        snprintf(rbcol, sizeof(rbcol), "%s%s%s", COLOR_YELLOW, rbbuf, COLOR_RESET);
        winner = COLOR_YELLOW "Close" COLOR_RESET;
        diff = 0.0;
    }

    if (diff > 0.0)
        printf("%-20s | %-15s | %-15s | %s (%.1f%% faster)\n", name, pycol, rbcol, winner, diff);
    else
        printf("%-20s | %-15s | %-15s | %s\n", name, pycol, rbcol, winner);
}

void run_json_compare_only()
{
    printf("\n" COLOR_BOLD COLOR_YELLOW "JSON-ONLY COMPARISON MODE\n" COLOR_RESET);
    print_table_header();

    char py_pattern[256], rb_pattern[256];
#ifdef _WIN32
    snprintf(py_pattern, sizeof(py_pattern), "python\\tests\\results_python_*.json");
    snprintf(rb_pattern, sizeof(rb_pattern), "ruby\\tests\\results_ruby_*.json");
#else
    snprintf(py_pattern, sizeof(py_pattern), "python/tests/results_python_*.json");
    snprintf(rb_pattern, sizeof(rb_pattern), "ruby/tests/results_ruby_*.json");
#endif

    char basenames[MAX_TESTS][MAX_NAME];
    int count = list_files_shell(py_pattern, basenames, MAX_TESTS);

    if (count <= 0)
    {
        printf(COLOR_RED "No JSON benchmark results found.\n" COLOR_RESET);
        return;
    }

    for (int i = 0; i < count; i++)
    {
        char testname[MAX_NAME];
        strncpy(testname, basenames[i], MAX_NAME);
        testname[MAX_NAME - 1] = '\0';

        char out_py[512], out_rb[512];
        snprintf(out_py, sizeof(out_py), "python/tests/results_python_%s.json", testname);
        snprintf(out_rb, sizeof(out_rb), "ruby/tests/results_ruby_%s.json", testname);

        double pyops = extract_ops(out_py);
        double rbops = extract_ops(out_rb);

        print_comparison_row(testname, pyops, rbops);
    }

    printf("=============================================================\n");
    printf(COLOR_GREEN "JSON summary completed.\n" COLOR_RESET);
}

/* ---------- main ---------- */
int main(int argc, char *argv[])
{
    char py_pattern[256], rb_pattern[256];
#ifndef _WIN32
    snprintf(py_pattern, sizeof(py_pattern), "python/tests/*.py");
    snprintf(rb_pattern, sizeof(rb_pattern), "ruby/tests/*.rb");
#else
    snprintf(py_pattern, sizeof(py_pattern), "python\\tests\\*.py");
    snprintf(rb_pattern, sizeof(rb_pattern), "ruby\\tests\\*.rb");
#endif

    char names[MAX_TESTS][MAX_NAME];
    int count = list_files_shell(py_pattern, names, MAX_TESTS);

//     if (argc > 1 && strcmp(argv[1], "-json") != 0)
//     {

//         init_mutex();
//         if (count <= 0)
//         {
//             printf(COLOR_YELLOW "Warning: no python tests found using pattern %s\n" COLOR_RESET, py_pattern);
//             destroy_mutex();
//             return 1;
//         }

//         ensure_dir("python/tests");
//         ensure_dir("ruby/tests");
//         return 0;
//     }
//     /* spawn threads for all python+ruby runs */
// #ifdef _WIN32
//     HANDLE threads[MAX_TESTS * 2];
//     int thcount = 0;
// #else
//     pthread_t threads[MAX_TESTS * 2];
//     int thcount = 0;
// #endif

//     for (int i = 0; i < count; ++i)
//     {
//         const char *testname = names[i];

//         /* python job */
//         job_t *jpy = (job_t *)malloc(sizeof(job_t));
//         strncpy(jpy->testname, testname, sizeof(jpy->testname));
//         strcpy(jpy->lang, "python");
//         jpy->runs = DEFAULT_RUNS;
//         jpy->ops = DEFAULT_OPS;
//         snprintf(jpy->outpath, sizeof(jpy->outpath), "python/tests/results_python_%s.json", testname);

// #ifdef _WIN32
//         threads[thcount] = CreateThread(NULL, 0, worker_thread, jpy, 0, NULL);
//         if (threads[thcount])
//             thcount++;
// #else
//         if (pthread_create(&threads[thcount], NULL, worker_thread, jpy) == 0)
//             thcount++;
// #endif

//         /* ruby job */
//         job_t *jrb = (job_t *)malloc(sizeof(job_t));
//         strncpy(jrb->testname, testname, sizeof(jrb->testname));
//         strcpy(jrb->lang, "ruby");
//         jrb->runs = DEFAULT_RUNS;
//         jrb->ops = DEFAULT_OPS;
//         snprintf(jrb->outpath, sizeof(jrb->outpath), "ruby/tests/results_ruby_%s.json", testname);

// #ifdef _WIN32
//         threads[thcount] = CreateThread(NULL, 0, worker_thread, jrb, 0, NULL);
//         if (threads[thcount])
//             thcount++;
// #else
//         if (pthread_create(&threads[thcount], NULL, worker_thread, jrb) == 0)
//             thcount++;
// #endif
//     }

//     /* wait for all threads */
// #ifdef _WIN32
//     WaitForMultipleObjects(thcount, threads, TRUE, INFINITE);
//     for (int i = 0; i < thcount; ++i)
//         CloseHandle(threads[i]);
// #else
//     for (int i = 0; i < thcount; ++i)
//         pthread_join(threads[i], NULL);
// #endif

    printf("\n\n" COLOR_BOLD COLOR_YELLOW "BENCHMARK RESULTS" COLOR_RESET "\n");
    print_table_header();

    for (int i = 0; i < count; ++i)
    {
        char *testname = names[i];
        char out_py[512], out_rb[512];
        snprintf(out_py, sizeof(out_py), "python/tests/results_python_%s.json", testname);
        snprintf(out_rb, sizeof(out_rb), "ruby/tests/results_ruby_%s.json", testname);

        double pyops = extract_ops(out_py);
        double rbops = extract_ops(out_rb);
        print_comparison_row(testname, pyops, rbops);
    }

    destroy_mutex();
    printf("=============================================================\n");
    printf(COLOR_GREEN "All tests completed.\n" COLOR_RESET);
    return 0;
}
