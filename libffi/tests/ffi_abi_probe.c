#include <ffi.h>
#include <stddef.h>
#include <stdio.h>

int main(void)
{
    printf("cif=%zu\n", sizeof(ffi_cif));
    printf("closure=%zu\n", sizeof(ffi_closure));
    printf("raw=%zu\n", sizeof(ffi_raw));
    printf("arg=%zu\n", sizeof(ffi_arg));
    printf("type=%zu\n", sizeof(ffi_type));
    printf("status=%zu\n", sizeof(ffi_status));
    printf("cif_arg_types=%zu\n", offsetof(ffi_cif, arg_types));
    printf("cif_flags=%zu\n", offsetof(ffi_cif, flags));
    printf("closure_cif=%zu\n", offsetof(ffi_closure, cif));
    printf("closure_user_data=%zu\n", offsetof(ffi_closure, user_data));
#if defined(X86_WIN64)
    printf("call_abi=%d\n", FFI_WIN64);
#else
    printf("call_abi=%d\n", FFI_DEFAULT_ABI);
#endif
    printf("trampoline=%d\n", FFI_TRAMPOLINE_SIZE);
    printf("closures=%d\n", FFI_CLOSURES);
    printf("native_raw=%d\n", FFI_NATIVE_RAW_API);
#ifdef FFI_TARGET_HAS_COMPLEX_TYPE
    printf("complex=1\n");
#else
    printf("complex=0\n");
#endif
#ifdef FFI_GO_CLOSURES
    printf("go_closures=1\n");
#else
    printf("go_closures=0\n");
#endif
    return 0;
}
