/* Copyright (c) 2026 Kevin Collins. SPDX-License-Identifier: MPL-2.0-no-copyleft-exception */
#define _GNU_SOURCE
#include <stddef.h>
#include <pwd.h>
#include <grp.h>
#include <shadow.h>
#include <dlfcn.h>

int nx_has_setgroupent(void) { return dlsym(RTLD_DEFAULT, "setgroupent") != NULL; }

size_t nx_passwd_size(void) { return sizeof(struct passwd); }
size_t nx_group_size(void) { return sizeof(struct group); }
size_t nx_shadow_size(void) { return sizeof(struct spwd); }
size_t nx_shadow_offset(unsigned int index) {
    const size_t offsets[] = {
        offsetof(struct spwd, sp_lstchg), offsetof(struct spwd, sp_min),
        offsetof(struct spwd, sp_max), offsetof(struct spwd, sp_warn),
        offsetof(struct spwd, sp_inact), offsetof(struct spwd, sp_expire),
        offsetof(struct spwd, sp_flag)
    };
    return offsets[index];
}
