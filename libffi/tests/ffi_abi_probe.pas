program ffi_abi_probe;

uses
  ffi;

var
  Cif: ffi_cif;
  Closure: ffi_closure;

begin
  Writeln('cif=', SizeOf(ffi_cif));
  Writeln('closure=', SizeOf(ffi_closure));
  Writeln('raw=', SizeOf(ffi_raw));
  Writeln('arg=', SizeOf(ffi_arg));
  Writeln('type=', SizeOf(ffi_type));
  Writeln('status=', SizeOf(ffi_status));
  Writeln('cif_arg_types=', PtrUInt(@Cif.arg_type) - PtrUInt(@Cif));
  Writeln('cif_flags=', PtrUInt(@Cif.flags) - PtrUInt(@Cif));
  Writeln('closure_cif=', PtrUInt(@Closure.cif) - PtrUInt(@Closure));
  Writeln('closure_user_data=', PtrUInt(@Closure.user_data) - PtrUInt(@Closure));
  Writeln('call_abi=', Ord(FFI_DEFAULT_ABI));
  Writeln('trampoline=', FFI_TRAMPOLINE_SIZE);
  Writeln('closures=', Ord(FFI_CLOSURES));
  Writeln('native_raw=', Ord(FFI_NATIVE_RAW_API));
  Writeln('complex=', Ord(FFI_TARGET_HAS_COMPLEX_TYPE));
  Writeln('go_closures=', Ord(FFI_GO_CLOSURES));
end.
