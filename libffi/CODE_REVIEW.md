# LibFFI relocation review

Reviewed 2026-10-18 before changing inherited implementation. Authorized by
“move libffi”, following the package relocation workflow. Final verification:
2026-10-18, native Linux x86-64, NexusFPC 3.3.1, libffi 3.4.6.

## Baseline and ownership

The baseline is NexusFPC `packages/libffi`, revision
`83d89d45657c66a5ae4636233cb16961fd00a1ed`, Git tree
`a386598c08cbe28ad598a09dc2679506af547862`. All nine inherited files are
hashed in [review/baseline-hashes.json](review/baseline-hashes.json).
The untouched snapshot is at
`/media/kcollins/dev/worktree/libffi-relocation/untouched`. The immutable Git tree
preserves the original source without a second maintained provider or a tracked
source/evidence archive.

The review covered both Pascal units, namespace wrappers/map, original README,
C/Pascal ABI probes and PowerShell runner. `NXRP.LibFFI` now owns the sole Pascal
provider at `packages/nexus-packages/libffi`. Original notices, wrappers, ABI
probes and namespace mapping remain; `COPYING.FPC` and `COPYING.txt` accompany
source headers. Examples remain centralized in Nexus Lab, with working recipes.
See root [ATTRIBUTIONS.md](../../../ATTRIBUTIONS.md#libffi-pascal-binding).
Native libffi is a separate external C library, not source supplied by this
Pascal package.

## Proven findings and corrections

Each regression was built against the untouched snapshot before its correction.
Cases run separately for baseline proof so an invalid native call cannot corrupt
later measurements. All tests use nxtest directly.

| Finding | Baseline evidence | Correction and regression |
| --- | --- | --- |
| Hidden managed results confused callback signatures with invocation values | `ManagedCallback`: ERangeError; `NoArgManagedResult`: EAccessViolation | Explicit callback preparation mode; pass the actual value vector including hidden results, even with zero explicit arguments. Both cases now pass. |
| Narrow integer results overwrite caller storage | `NarrowResult`: a LongInt result destroyed an adjacent four-byte sentinel | Use an internal `ffi_arg` result buffer for narrower integer returns and copy only the declared bytes. Guard remains intact. |
| Generated aggregate types leak after calls and callback destruction | `InvokeOwnership`: 160,000 bytes retained after 1,000 calls; `CallbackOwnership`: 80,000 bytes retained after 500 callback create/call/free cycles | Own the null-terminated element arrays explicitly; free constructed type trees after invocation and closure teardown. Each array-of-record field element owns a distinct child. Measured heap use is stable after warmup. Constructor/preparation exception cleanup follows the same ownership path. |
| Large Pascal sets use a different ABI from C structs | `LargeSetInvoke` and `LargeSetResult`: EAccessViolation with a 96-bit Pascal set | Pass large sets indirectly and use the hidden result pointer required by NexusFPC. Keep set fields embedded in record descriptors. `SetField` remains a passing control. |
| Sixteen-byte records containing shortstrings require pointer arguments/results on x86-64 SysV | `ShortStringField` and `ShortStringRecordResult`: EAccessViolation; `ShortStringRecordCallback`: wrong result | Detect shortstring fields, including nested records, for this compiler rule. Use indirect arguments in both invocation and callbacks, and a hidden result pointer. All three cases pass. |

The native result buffer also isolates heap-growth probes from the independent
return-buffer overwrite: those probes deliberately provide `ffi_arg` storage.
The ownership tests exercise a record containing two record-array elements,
which would expose duplicate ownership after enabling recursive cleanup.

Compiler evidence for ABI corrections is in NexusFPC
`compiler/x86_64/cpupara.pas`: `ClassifyArgument` classifies non-small sets and
shortstrings as memory; `Push_Addr_Param` passes 16-byte memory-class records by
reference; `Ret_In_Param` selects hidden results. Disassembly independently
confirmed that the test's large-set and 16-byte shortstring-record functions
dereference their incoming pointer. The record-specific correction is conditional
on x86-64 Unix; it does not invent an unverified cross-target convention.

## Review candidates cleared or limited

- Callback argument indexing already advances `argidx`; the initial suspicion
  was incorrect. `CallbackArguments` passes unchanged on baseline and final.
- A test assumption that a 24-bit Pascal set occupies three bytes was invalid;
  it was discarded. The retained large-set cases check an actual 96-bit set.
- The shortstring field enumerator appears to include an extra byte, but changing
  that enumeration did not correct the demonstrated call failure. Its actual
  cause was the compiler's reference-passing rule. The enumerator is unchanged;
  no separate behavior failure is claimed for it.
- Set descriptor initialization is now explicit in the owned struct constructor.
  No independent uninitialized-size failure was reproduced or counted.
- Raw `ffi.pas` declarations required no change. All 16 inherited ABI-probe values
  match the installed native libffi headers and library.

## Package and consumer integration

`LibFFI.nxpackage` builds both Pascal units with NexusFPC. Package metadata and
both catalogs register `NXRP.LibFFI`. Lua's dependency documentation, the RTL test
recipe and the mobile example now refer to this sole provider. Native Lab recipes
for the raw FFI example and RTTI interceptor example are registered in Lab Forge.
The Lua published-RTTI test recipe now uses the current native nxbuild language
rather than its obsolete Windows-only recipe form.

No production compiler or RTL source imports libffi. Lua.Plugin imports
`ffi.manager` outside Win64 x86-64; that unit registers an optional RTTI function
call manager. The package relocation does not make it a standard RTL dependency,
change compiler bootstrap, introduce compiler variants, or change build stages.

All generated tools, units, libraries, executables, temporary files and proof
logs are outside source checkouts under
`/media/kcollins/dev/worktree/libffi-relocation`. The inherited PowerShell probe
now requires an explicit output directory too.

## Final verification

| Check | Result |
| --- | --- |
| Untouched baseline, 13 isolated cases | 3 pass; 10 fail/error as described above |
| Relocated direct nxtest suite, range/overflow checks enabled | 13 passed; 0 failed; 0 errors; 0 skipped |
| Native C/Pascal ABI comparison | All 16 values match libffi 3.4.6 |
| LibFFI.nxpackage | Both units build |
| RTLObjPasTests | 508 passed; 0 failed; 0 errors; 0 skipped |
| Lua TestPublishedRTTI | Passes integer, floating-point and managed-string published-method checks |
| Lab FFI simple example | Runs; expected strings and lengths 11 and 13 |
| Lab RTTI interceptor example | Runs; expected modified result, handled exception and restored dispatch |
| Lab mobile plugin | Native Linux shared library links using relocated ffi.manager |
| Package metadata, workspace/repository catalogs, Lab Forge | NexusScript validation passes |
| Active source paths | No dependency on removed NexusFPC packages/libffi remains |

Commands and output are saved in the external worktree's `logs`,
`baseline-results.json`, `consumer-results.json`, `metadata-results.json` and
`results.json`. `Baseline.nxproject` builds the current regressions against the
untouched source; `verify.py baseline`, `verify.py final` and `verify.py abi`
record the corresponding proof and final checks there. The two Nexus Lab example
recipes and committed package/test recipes reproduce ordinary builds.

Limits: this relocation executes Linux x86-64 only. Windows, Apple, Android and
other CPU ABI/runtime probes were not run. The plugin was linked, not executed
inside Solar2D. The finite regression suite and inherited declaration probes do
not establish every aggregate, calling convention or cross-platform ABI.
No FPCUnit bridge or Delphi validation is involved.
