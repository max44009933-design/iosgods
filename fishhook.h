#ifndef fishhook_h
#define fishhook_h

#include <stddef.h>
#include <stdint.h>

// 🌟 核心防護：只包住函數，避開系統庫！
#ifdef __cplusplus
extern "C" {
#endif

struct rebind_msg { const char *name; void *replacement; void **replaced; };
int rebind_symbols(struct rebind_msg *rebinds, size_t rebinds_nel);

#ifdef __cplusplus
}
#endif

#endif
