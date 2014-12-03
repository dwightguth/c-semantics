#ifndef _KCC_ERRNO_H
#define _KCC_ERRNO_H
#include <kcc_settings.h>

#define _ERRNO_H 1
#define __ASSEMBLER__
#include <bits/errno.h> /* get system-specific errno constants */
#undef __ASSEMBLER
#undef errno
extern int *__kcc_errno();
#define errno *__kcc_errno()

#endif
