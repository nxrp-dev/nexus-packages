# SQLite nxtest results - 2026-10-14

The complete existing suite passes against `SQLite.nxpl`, requiring `nxrtl.nxpl`,
and the SQLite 3.53.4 C runtime compiled by LLVM through `SQLite.nxpackage`.

**28 passed; 0 failures; 0 errors; 0 skipped.** No test cases were removed or weakened.
The test helpers now accept a C library path argument instead of assuming the old
executable-relative `runtime/win64` layout.

The native import table confirms the executable consumes both runtime packages.
The C DLL exports exactly the same 378 symbol names as the previous Win64 DLL.
No compiler, nxbuild implementation, SQLite binding or dataset changes were needed.

The new test project retains range, overflow, I/O and line information settings.
Executable-local heap tracing cannot be used with this SDK's package-startup
allocation ordering: it reports an invalid block before the suite starts.
It is omitted from the package-consuming recipe; heap-leak verification is not
claimed. The issue requires separate shared-RTL diagnostic work.

An initial native recipe incorrectly set `SQLITE_DEFAULT_RECURSIVE_TRIGGERS=1`
after reading the previous DLL's compile-option strings. The trigger test caught
recursive execution. SQLite lists that option even when it is zero; removing the
incorrect override restored the previous behavior and all tests passed. The tests
also passed against the previous DLL during diagnosis. Auto-vacuum likewise uses
its original upstream default.

Win64 is verified. Linux and Win32 package execution were not run. The package
includes Linux native library settings and uses Abbrevia's shared environment
module; a matching Linux package SDK must be configured there before a full build.
Changes remain uncommitted.
