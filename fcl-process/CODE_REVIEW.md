# FCL Process code review

Review date: 2026-10-15. Reviewed NexusFPC revision:
`b7361861c09b1bcc0d3ca293639539fda644c594`.
The last commit affecting the reviewed package is
`6c5bd2eef00b97fe12e5b1e87310ec60313b8c52` (2026-10-14).

The original static review identified fourteen runtime correctness findings.
It was saved before relocation, which preserved all reviewed source bytes.
The descriptions below describe that original snapshot; source line numbers are
from that snapshot.

## Regression verification and corrections

On 2026-10-15, one nxtest case was added for each finding in
[tsFCLProcessTests.pas](test/tsFCLProcessTests.pas). The same cases were compiled
against an untouched source snapshot before production changes, then against
the corrected source with NexusFPC 3.3.1 on x86_64 Linux.

**Before:** 11 failures, 0 passes, 3 platform skips.
**After:** 11 passes, 0 failures/errors, 3 platform skips.

| Finding / case suffix | Baseline evidence | Current status |
| --- | --- | --- |
| 01 InactiveProcessSignals | Isolated probe terminated on SIGTERM, exit status 15. | Fixed: reject signals without a positive, running child. Also checks failed startup and completed children. |
| 02 IntegerWireWidths | Decoder requested five bytes for an Integer; guarded input stopped the overwrite. | Fixed: validate widths, initialize narrow results, require complete reads/writes. |
| 03 PipelineOwnership | Connecting a peer changed the process Owner. | Fixed: non-owning peer references, incoming self-reference validation, disconnection and component notifications, including shared peer references. |
| 04 CloseInputDeliversEOF | Child did not receive EOF after CloseInput. | Fixed: close the current handle owner, clear its stream, and avoid recreating a closed stream. |
| 05 CopySelectedPipe | Copying stderr returned stdout. | Fixed: read the supplied pipe; stdout remains available independently. |
| 06 ConcurrentFIFOFrames | Two barrier-synchronized writers corrupted a 128 KiB payload. | Fixed: buffer the frame and hold a per-message advisory FIFO lock; disable conflicting open-time shared locks on both endpoints. |
| 07 WindowsServiceShutdown | Requires a Windows SCM service execution. | Open: Windows case written; not compiled or run here. No service fix applied. |
| 08 WindowsArgumentBoundaries | Requires a Windows argument-echo child. | Open: Windows case written; not compiled or run here. No quoting fix applied. |
| 09 WindowsProcessHandleReuse | Requires Windows process handle counts. | Open: Windows case written; not compiled or run here. No handle-reuse fix applied. |
| 10 CallbackHandleAcquisition | Valid callback handle raised “No handle set”. | Fixed: validate the callback result. |
| 11 InfiniteWaitShutdown | Idle receiver exceeded the parent's 10-second deadline. | Fixed: cap the existing receiver's wait at 50 ms so it can observe termination. |
| 12 DiscardNewOwnership | The rejected message's destructor was not called. | Fixed: dispose of discarded messages, return acceptance from Push and notify only on insertion. |
| 13 SyncTimeoutOwnership | 128 timeouts retained 8,192 heap bytes. | Fixed: own the response stream in finally, transferring ownership only when returning it to the caller. |
| 14 TimeoutAcrossSecondBoundary | A 300 ms wait expired after approximately 150 ms. | Fixed: measure elapsed time with GetTickCount64. |

[Test instructions](test/README.md) document the Nexus build command, fixture
isolation and platform prerequisites. Raw local baseline and corrected logs are
under `output/fcl-process-tests/`. Windows and other non-Linux targets are
unverified; skipped cases are not evidence of a fix. The Windows and dummy timed
wait parameter names were updated to match the shared declaration, without a
behavior change.

The changed process/pipe and IPC units compile, including standalone `pipesipc`.
`nxbuild` and the NexusScript CLI were rebuilt with the corrected process units;
the rebuilt nxbuild successfully built this regression project. A broader unit
compile also found two `processunicode` type mismatches in Unix `MakeCommand`
and environment conversion. Both reproduce against the untouched baseline.
That pre-existing compile limitation is outside these fourteen runtime findings;
`processunicode` is not used by the regression executables and remains unchanged.

## Original findings

## 1 P1 Unix Terminate can signal the caller's process group

Source: [Terminate](src/unix/process.inc#L545).

`Terminate` calls `fpKill(Handle, SIGTERM)` without checking that a child was
started. A newly created object's process handle is zero. On Linux,
`kill(0, SIGTERM)` signals the caller's process group, so cleanup following a
failure before process startup can terminate the caller and other group members.
`Suspend` and `Resume` also signal the unchecked handle.

Suggested correction: validate child identity and lifecycle state before
signaling. Verify calls before startup, after failed startup and after exit.
The PID-zero behavior is specified by the
[Linux kill manual](https://man7.org/linux/man-pages/man2/kill.2.html).

## 2 P1 IPC integer decoding permits memory corruption

Source: [ReadInt and WriteInt](src/syncipc.pas#L141).

`ReadInt` reads a payload-supplied byte count directly into an `Integer` result
without bounding the count. A payload with a width larger than `SizeOf(Integer)`
and sufficient bytes overwrites adjacent memory. Short reads and smaller widths
also leave unspecified result bytes. `WriteInt` similarly permits reading past
its integer argument when given an oversized width.

Suggested correction: validate supported widths, initialize and decode the
result explicitly, and require complete reads. Verify malformed widths,
truncated payloads and supported smaller-width integers.

## 3 P1 Pipeline assignment corrupts component ownership

Source: [SetProcess](src/processbody.inc#L988).

The setter calls `FProcess.RemoveComponent(FOwnerProcess)` on both sides of the
assignment. `TComponent.RemoveComponent` clears the supplied component's owner
even when that component is absent from the receiver's component list. Assigning
a pipeline peer can therefore clear the caller's owner while leaving it in its
original owner's list. That breaks later component destruction. No peer lifetime
notification is established. The setter additionally checks the old peer rather
than the incoming value for self-reference and dereferences the peer after
assigning `nil` when disconnecting.

Suggested correction: model this as a non-owning peer reference with proper
lifetime notification, validate the incoming peer and handle disconnection.
Verify that connecting and disconnecting independently owned processes leaves
both ownership graphs intact and that destroying a peer clears the reference.

## 4 P1 CloseInput fails after the input stream has been accessed

Source: [ResolveStream](src/processbody.inc#L1104),
[CloseOurHandle](src/processbody.inc#L1120),
[CloseInput](src/processbody.inc#L500).

`ResolveStream` transfers the pipe handle into `FStream` and invalidates
`FOurHandle`. `CloseInput` subsequently calls `CloseOurHandle`, which sees only
the invalid field and leaves the stream-owned pipe open. Writing through
`Process.Input`, calling `CloseInput` and waiting for a child that requires EOF
can consequently hang indefinitely. The other explicit pipe-close methods
share this ownership issue.

Suggested correction: close whichever object currently owns the handle and
update descriptor state consistently. Verify EOF delivery after accessing or
writing through the input stream.

## 5 P1 The stream-copy overload reads the wrong pipe

Source: [ReadInputStream](src/processbody.inc#L694).

The overload taking a destination `TStream` checks availability on argument `p`
but reads from `Output`. Passing `Stderr` can consume stdout or block on an empty
stdout pipe while stderr remains unread.

Suggested correction: read from `p`. Verify a child that writes only stderr and
a child that writes distinct data to both output streams.

## 6 P1 Concurrent Unix IPC clients can corrupt message framing

Source: [SendMessage](src/unix/simpleipc.inc#L92),
[ReadMessage](src/unix/simpleipc.inc#L197).

The shared FIFO sender writes the header and payload separately while permitting
multiple connected clients. Two clients can produce header A, header B, payload
B, payload A. The receiver then consumes another message's header as payload
and loses framing. Atomicity of an individual pipe write does not make the two
writes an atomic message; large payloads add further interleaving exposure.

Suggested correction: serialize complete framed messages across writers,
including payloads above the pipe's atomic-write limit. Verify concurrent
clients with distinct payloads and multiple message sizes.

## 7 P1 Windows service shutdown leaves its worker running

Source: [ServiceController](src/fpsimpleservice.pas#L366),
[ServiceMain](src/fpsimpleservice.pas#L397).

The stop handler requests thread termination and signals the stop event.
`ServiceMain` then closes the event and reports `SERVICE_STOPPED` without joining
or freeing `FServiceThread`. A worker performing delayed cleanup can continue
while the application destroys resources, including its event log.

Suggested correction: coordinate termination and worker completion, then free
the worker before reporting final shutdown and releasing shared resources.
Verify a worker that takes time to finish after receiving the stop request.

## 8 P2 Windows argument serialization loses argument boundaries

Source: [MaybeQuoteIfNotQuoted](src/win/process.inc#L162),
[parameter assembly](src/win/process.inc#L209).

The quoting helper handles spaces only and leaves strings containing quotes
unchanged. An empty parameter becomes only a separator and disappears. An
argument containing a tab is emitted without quoting and can become multiple
arguments in the child. Literal quotes are not escaped to preserve their data.

Suggested correction: serialize arguments for the intended child argument
parser. Verify empty arguments, tabs, literal quotes and whitespace-containing
paths with an argument-echoing child.

## 9 P2 Reusing a Windows TProcess leaks handles

Source: [SysExecute](src/win/process.inc#L251),
[Execute](src/processbody.inc#L488),
[CloseProcessHandles](src/win/process.inc#L35).

Each successful execution overwrites `FProcessHandle` and `FThreadHandle`.
`Execute` resets the I/O descriptors but does not close the previous process
handles. Those handles are otherwise closed only at object destruction, which
can close only the most recently stored pair. Repeated execution leaks the
earlier pairs.

Suggested correction: close and clear handles from a completed execution before
replacing them. Verify repeated executions using one object and check handle
counts.

## 10 P2 Callback-supplied handles are rejected

Source: [CreateCustomHandle](src/processbody.inc#L1080).

`OnGetHandle` can supply a valid handle through `Result`, but the following
validation checks `FCustomHandle` instead. When that field retains its default
invalid value, callback-based handle acquisition always raises despite the
valid returned handle.

Suggested correction: validate the resolved handle. Verify acquisition using
only the callback and verify its close-ownership contract.

## 11 P2 An IPC server with an infinite wait cannot stop

Source: [StopThread](src/simpleipc.pas#L785),
[worker receive loop](src/simpleipc.pas#L662),
[Unix receiver](src/unix/simpleipc.inc#L188),
[Windows receiver](src/winall/simpleipc.inc#L222).

`StopThread` sets `Terminated` and calls `WaitFor` without waking the receiver.
With `ThreadTimeout = -1`, the worker can remain in an indefinite receive wait
when there are no incoming messages. Shutdown never reaches the next check of
the termination flag.

Suggested correction: make the receive wait interruptible during termination.
Verify stopping an idle server configured for an infinite wait.

## 12 P2 Discarding new IPC messages leaks them

Source: [PrepareToPush and Push](src/simpleipc.pas#L449),
[PushMessage](src/simpleipc.pas#L919).

When a bounded queue using `ipcmoaDiscardNew` is full, `PrepareToPush` returns
false. `Push` silently returns without owning or freeing the incoming message.
The caller assumes success, emits the queued notification and also does not
free it. Every discarded message leaks its object and payload.

Suggested correction: expose acceptance or dispose of rejected messages and
notify only on actual insertion. Verify repeated overflow with the discard-new
policy and check object/payload cleanup.

## 13 P2 Synchronous IPC timeouts leak the result stream

Source: [SendSyncMessage](src/syncipc.pas#L546).

The general result-conversion overload allocates `resStream`, then frees it only
inside recognized result-type branches. A timeout returns `mtUnknown`, bypasses
every branch and reaches a `finally` block that frees only `msgStream`.
Exceptions before branch cleanup have the same missing ownership protection.

Suggested correction: keep result-stream ownership in a `finally` block,
releasing ownership only when returning the stream to the caller. Verify
timeouts and exceptional responses.

## 14 P2 Unix timed waits can expire early across a second boundary

Source: [WaitOnExit](src/unix/process.inc#L488).

The deadline calculation adds microseconds without carrying overflow into the
seconds field. A 200 ms timeout beginning at a fractional time of .900 seconds
constructs an unnormalized deadline and can expire at the next second boundary,
after approximately 100 ms.

Suggested correction: normalize the deadline or use a monotonic elapsed-time
calculation. Verify timeouts beginning near a second boundary.

## 2026-10-16 native retained-test conversion

Useful retained behavior tests now use nxtest directly. The former FPCUnit
helpers and runners were removed, with their originals preserved in hashed
archives. The [retirement report](../../../docs/migrations/fpcunit/README.md) records conversions,
corrected invalid expectations, before/after results and verification limits.

## 15 Unix empty process arguments (corrected)

Discovered and corrected 2026-10-19 during the direct nxbuild Linux engine build.
The owner approved the two-line allocation/copy correction after reviewing the
source-level diagnosis. No compiler, RTL, bootstrap or threading change was made.

`src/unix/process.inc`, `StringsToPCharList`, previously called `StrNew` for each
argument. The retained RTL's `StrNew` returns nil for an empty string. That nil
entry terminated Unix `argv`, silently dropping the empty argument and every
argument after it. `FreePCharList` also stopped there, leaking later allocations.

The correction replaces that call with `StrAlloc(Length(S)+1)` and
`StrPCopy(Result[i],S)`. Every argument now has an allocated, zero-terminated
buffer, including an empty argument. The existing StrDispose cleanup remains
correct, and nil occurs only at the list terminator.

The actual NXTest `FCLProcess.Review.15UnixEmptyArgument` is unchanged between
the failing and corrected runs. It invokes native printf with an empty argument
between `before` and `after`:

- Before: expected `<before><><after>`, actual `<before>`; one unfreed 10-byte
  allocation for the later argument.
- After: passes with `<before><><after>`; heap tracing reports zero unfreed blocks.
- Full migrated Process regression recipe: **12 passed, 0 failures/errors,
  3 Windows-only skips** on x86-64 Linux.
- Rebuilt nxbuild: the independent Python argv probe now preserves
  `['-c', '', 'tail']`, matching direct execution.

Evidence root: `/media/kcollins/dev/worktree/nxproject-unified-wpoyr_f5`.
The original failing run remains in `fcl-process-open-finding/regression.log`.
`process-empty-argument-fix/` contains the original include, before/after hashes,
unchanged-regression compile command/log, passing heap report and rebuilt CLI
argv probe. `process-fix-suite-1792403795442012886-*` records the real full-suite
recipe build/run. Non-Linux Unix targets and native Windows were not run.
