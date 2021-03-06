// this include was added to the tests by running:    for fil in *.c; do sed -i '1i#include "fsl-header.h"' $fil; done
// the below assumes size_t, and in GCC __SIZE_TYPE__, are unsigned ints, as in 20020406-1.c
// it would be idea for the tests to include precisely what they need, but this allows us to add dependencies as we discover them
// #define size_t unsigned int
#include <kcc_settings.h>
typedef unsigned int size_t;
void exit(int);
void abort(void);
void* malloc(size_t);
void* malloc(size_t);
void free(void*);
int strcmp(const char *, const char *);
char* strncpy(char * restrict, const char * restrict, size_t);
size_t strlen(const char *s);
char *strcpy(char * restrict, const char * restrict);
void* memset(void *, int, size_t);
int printf(const char * restrict, ...);

#define __builtin_constant_p(X) 0

#undef size_t
