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

#define MAX_LINE 1024

void run_tests(const char *folder, const char *extension, const char *interpreter)
{
    char list_cmd[1024];
    char line[MAX_LINE];

#ifdef _WIN32
    snprintf(list_cmd, sizeof(list_cmd), "dir /b \"%s\" | findstr %s > test_list.tmp", folder, extension);
#else
    snprintf(list_cmd, sizeof(list_cmd), "ls \"%s\" | grep \"%s\" > test_list.tmp", folder, extension);
#endif

    system(list_cmd);

    FILE *fp = fopen("test_list.tmp", "r");
    if (!fp)
    {
        printf("Failed to generate test list for %s\n", folder);
        return;
    }

    printf("\n====================================\n");
    printf("Running %s tests from %s\n", extension, folder);
    printf("====================================\n");

    while(fgets(line, sizeof(line), fp))
    {
        line[strcspn(line, "\n")] = 0;
        char fullpath[2048];
        int n1 = snprintf(fullpath, sizeof(fullpath), "%s%c%s", folder, PATH_SEP, line);

        if (n1 < 0 || n1 >= (int)sizeof(fullpath))
        {
            printf("Path too long, skippping: %s\n", line);
            continue;
        }

        char run_cmd[4096];
        int n2 = snprintf(run_cmd, sizeof(run_cmd), "%s \"%s\"", interpreter, fullpath);

        if (n2 < 0 || n2 >= (int)sizeof(run_cmd))
        {
            printf("Command too long, skipping: %s\n", fullpath);
            continue;
        }

        printf("\n Running: %s\n", fullpath);
        int result = system(run_cmd);

        if (result != 0)
        {
            printf("Test failed: %s\n", fullpath);
            fclose(fp);
            remove("test_list.tmp");
            return;
        }
        else
            printf("Test passed: %s\n", fullpath);
    }

    fclose(fp);
    remove("test_list.tmp");
}

int main()
{
    run_tests("python/tests", ".py", "python3");
    run_tests("ruby/tests", ".rb", "ruby");

    printf("\n All tests completed successfully");
    return 0;
}