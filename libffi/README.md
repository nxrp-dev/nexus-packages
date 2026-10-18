# libffi binding

This package contains Pascal declarations for the external native libffi library
and an opt-in `ffi.manager` implementation of RTL RTTI invocation. Importing
`ffi.manager` registers its function-call manager for the process. The compiler
and RTL do not supply a native libffi binary.

The package is registered for Windows, Linux, macOS, iOS, the iOS simulator,
and native Android. Registration alone does not provide a linkable native
library. A consumer using `ffi.manager` must supply libffi built for its exact
CPU, operating system, and ABI. In particular, Android and Apple plugin builds
must include a suitable native libffi build in their final link inputs.
The Pascal import name is `ffi`; on Windows the runtime must be available under
the import name `ffi.dll` (or the build must provide an equivalent import
mapping). The locally tested MinGW binary is named `libffi-8__.dll`, so the
Win64 test used a copy named `ffi.dll` in its test output directory.

The Pascal ABI declarations must match the `ffi.h` and `ffitarget.h` used to
build that native library. The Win64 declarations have been compared with
libffi 3.4.6 headers using `tests/Check-LibFFIABI.ps1`. Run that probe against
the matching native headers on every target before shipping. Cross-compiling
the Pascal units alone is not an ABI test.
The probe checks the ABI selected for Pascal calls. On x86-64 Windows this is
`FFI_WIN64`, even when a MinGW-built libffi header names `FFI_GNUW64` as its
default; the latter describes the C compiler's long-double convention, not
the calling convention used for these Pascal RTTI calls.

On Windows, the probe can be run with:

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File packages/nexus-packages/libffi/tests/Check-LibFFIABI.ps1 `
  -FFIIncludeDir <path-to-target-libffi-headers> `
  -PascalCompiler <target-fpc> -CCompiler <matching-c-compiler> `
  -OutputRoot <absolute-worktree-directory>
```

When using a freshly bootstrapped NexusFPC compiler, also pass
`-PascalRTLDir <matching-rtl/units/target>` to disable ambient compiler
configuration and select its matching RTL.

The probe compiles a C and a Pascal program and compares their ABI layout and
feature values. For a cross target, compile and run both programs on that target
or an emulator with the same ABI; a host-only probe does not validate a cross
build. The published-method invocation check is
`packages/nexus-packages/lua/test/TestPublishedRTTI.pas` in Nexus.
On Win64, define `NX_TEST_FFI_MANAGER` to force that test through
libffi instead of the native RTTI manager.

## Nexus package

`NXRP.LibFFI` owns `ffi` and `ffi.manager`. The former NexusFPC
`packages/libffi` provider has been removed. This package is an application
capability; compiler bootstrap and the RTL build do not require it.

Build the package and its direct nxtest regressions from the Nexus root:

```sh
nxbuild /action=build /project=packages/nexus-packages/libffi/LibFFI.nxpackage
nxbuild /action=build /project=packages/nexus-packages/libffi/tests/LibFFITests.nxproject
../../worktree/libffi-relocation/tests/x86_64-linux/LibFFITests
```

The recipes select the native NexusFPC installation and write generated files
under `../../worktree/libffi-relocation`, outside all source checkouts. Keep
compiler temporary files there too by setting `TMPDIR` to a directory under
that worktree. The native libffi headers and library must be installed separately.

The 2026-10-18 relocation verified Linux x86-64 against libffi 3.4.6: all
13 direct regressions and 508 RTL tests passed, as did the Lua published-method
prerequisite check and both Lab examples. The mobile plugin linked; its Solar2D
runtime was not executed. The C and Pascal ABI probes agreed on all 16 reported
values. This relocation did not rerun other target ABIs or the inherited Windows
probe described above.

See [the saved review](CODE_REVIEW.md) for baseline proofs, fixes and verification
limits. Original examples remain centralized in Nexus Lab under
`examples/runtime/ffi` and `examples/runtime/object-pascal`; their recipes are
registered in `NexusLab.Forge.nxscript`. Original notices and the independent-module
license exception are preserved in `COPYING.FPC`, `COPYING.txt` and source headers.
Attribution and provenance are maintained in the root
[ATTRIBUTIONS.md](../../../ATTRIBUTIONS.md#libffi-pascal-binding).
