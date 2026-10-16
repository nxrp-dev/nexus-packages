# FCL Process regressions

The `FCLProcess.Review` nxtest suite registers one numbered case for each of
the fourteen findings in [the saved review](../CODE_REVIEW.md). The console
runner uses the ordinary nxtest registry, cases, contexts and results.

From the Nexus repository root, with nxbuild available:

```sh
nxbuild /project=packages/nexus-packages/fcl-process/test/FCLProcessTests.nxproject /action=build
output/fcl-process-tests/x86_64-linux/FCLProcessTests
```

The project builds both `FCLProcessTests` and its sibling `FCLProcessFixture`.
Compiler and platform paths come from
`projects/nxbuild/nxbuild.environment.nxscript`. Windows executables are in
`output/fcl-process-tests/x86_64-win64/` with `.exe` suffixes. Passing part of a
case name runs only matching cases, for example `FCLProcessTests 06Concurrent`.

Every case runs its probe in a child process. The parent enforces a ten-second
deadline (thirty seconds for Windows service and handle-reuse cases). On Unix,
each probe starts a new session; the parent kills remaining descendants in
that process group and removes its temporary files/FIFOs. This contains the
baseline signal-group bug and blocking shutdown defects. The integer test uses
a guarded stream to detect an oversized read before memory can be overwritten.
The FIFO test synchronizes two real writer processes and checks distinct
128 KiB payloads. The timeout leak test warms the allocator and measures live
heap bytes across 128 unanswered requests.

On Linux the verified result is **11 passed, 0 failed, 3 skipped**. The same
tests against the unmodified relocation snapshot produced **11 failed,
3 skipped**. Local evidence is in `output/fcl-process-tests/baseline/results.txt`
and `output/fcl-process-tests/x86_64-linux/results.txt`.

Windows cases have been written but have not been compiled or executed on this
host. Case 07 creates, starts, stops and removes a temporary Windows service;
it skips if SCM creation is denied. Its worker deliberately takes 400 ms to
complete cleanup after the stop request, and the case checks that cleanup has
finished when SCM reports `SERVICE_STOPPED`. The existing service worker thread
isolates blocking service work from SCM control handling. No helper thread is
added by the tests. Case 08 round-trips empty, tabbed, quoted and trailing-slash
arguments. Case 09 checks handle counts across 32 executions of one TProcess.
These three findings remain unfixed until failures can be demonstrated there.

Unix-specific cases 01, 06 and 14 skip on Windows. Other non-Linux platforms
have not been verified. Standalone `pipesipc` requires ObjFPC mode. A separate
unit compile found pre-existing `processunicode` type mismatches on the current
Linux toolchain, reproduced on both baseline and corrected sources; that unit
is not used by this suite.
