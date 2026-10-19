/* Copyright (c) 2026 Kevin Collins. SPDX-License-Identifier: MPL-2.0-no-copyleft-exception */
#include <stddef.h>
/* Deliberately lacks iconv_open/iconv_close and all libiconv-prefixed symbols. */
size_t iconv(void *handle, char **input, size_t *input_left,
             char **output, size_t *output_left) {
    (void)handle; (void)input; (void)input_left; (void)output; (void)output_left;
    return (size_t)-1;
}
