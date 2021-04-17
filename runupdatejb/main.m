// #import <Foundation/Foundation.h>
#include <dlfcn.h>
#include <spawn.h>
#include <stdio.h>
#include <sys/sysctl.h>
#include <sys/wait.h>
#include <unistd.h>

// #define BUFSIZE 1024

int main(int argc, char *argv[], char *envp[]) {
    @autoreleasepool {
        setuid(0);
        if (getuid() != 0) {
            return 1;
        }

        //NSLog(@"JailbreakUpdateChecker - run command");

        pid_t pid;
        posix_spawn(&pid, "/usr/sbin/jbupdate", NULL, NULL, NULL, NULL);  // (char *const *)args

        // No output can be retrieved by code below
        // I'm not enthusiastic enough about this tweak to struggle with how to fix it.

        // char *cmd = "/usr/sbin/jbupdate 2>&1";

        // char buf[BUFSIZE];
        // FILE *fp;

        // if ((fp = popen(cmd, "r")) == NULL) {
        //     printf("Error opening pipe!\n");
        //     return -1;
        // }

        // while (fgets(buf, BUFSIZE, fp) != NULL) {
        //     printf("%s", buf);
        // }

        // if (pclose(fp)) {
        //     printf("Command not found or exited with error status\n");
        //     return -1;
        // }

        return 0;
    }
}
