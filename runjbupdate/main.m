// #import <Foundation/Foundation.h>
#include <dlfcn.h>
#include <spawn.h>
#include <stdio.h>
#include <sys/sysctl.h>
#include <sys/wait.h>
#include <unistd.h>

#define BUFSIZE 1024

int main(int argc, char *argv[], char *envp[]) {
    @autoreleasepool {
        setuid(0);
        if (getuid() != 0) {
            return 1;
        }

        pid_t pid;
        char *envp[] = {
            "DYLD_INSERT_LIBRARIES=/Library/MobileSubstrate/DynamicLibraries/JailbreakUpdateChecker.dylib",
            NULL,
        };

        posix_spawn(&pid, "/usr/sbin/jbupdate", NULL, NULL, NULL, envp);

        return 0;
    }
}
