#include <stdio.h>
#include <stdlib.h>
#include <unistd.h>

int main(int argc, char *argv[]) {
    int opt = getopt(argc, argv, "n:");

    if (opt == '?' || opt < 0) {
        printf("Usage: test -n <number of messages>\n");
        exit(1);
    }

    int count = atoi(optarg);

    printf("Counting T-%d seconds...\n", count);

    for (int i = count; i > 0; i--) {
        printf(">> %d\n", i);
        sleep(1);
        fflush(stdout);
    }

    printf("Boom!!!");
}

