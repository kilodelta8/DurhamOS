// cpu.c
#include <stdio.h>
#include <stdlib.h>
#include <sys/time.h>
#include <assert.h>
#include "common.h"  

int main(int argc, char *argv[]){

    if (argc != 2){
        fprintf(stderr, "Usage: cpu <string>\n");
        exit(1);
    }

    char *str = argv[1];
    while (1){
        Spin(1);  // error
        printf("%s\n", str);
    }

    return 0;
}