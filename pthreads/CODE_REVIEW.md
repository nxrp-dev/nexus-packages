# pthreads relocation review

Reviewed 2026-10-18 before inherited implementation changes; final native
verification completed 2026-10-18. Baseline: NexusFPC
`4f78c6c072c538cb2514a0a8226d53bca982cdf0:packages/pthreads`, Git tree
`3c3cf80eb217998e6238612af731d7bef81fc843`. All 7 inherited files are
recorded in [review/baseline-hashes.json](review/baseline-hashes.json).
Untouched snapshot:
`/media/kcollins/dev/worktree/unix-bindings-relocation/untouched/pthreads`.
Git preserves the original source/notices without a tracked duplicate archive.
See [central provenance](../../../ATTRIBUTIONS.md#unix-pthreads).

The review covered the wrapper and Linux/Android/BSD include declarations,
namespace material and dormant AIX include. The AIX file is not selected by the
unit and remains preserved material, without introducing AIX support.

## Proven findings and fixes

| Finding | Untouched-source proof | Fix / direct nxtest case |
|---|---|---|
| Linux FAST mutex constant aliases ADAPTIVE instead of TIMED/NORMAL | Independent C header value disagrees | Correct alias; `FastMutexConstant` |
| Linux default rwlock constant aliases WRITER instead of READER | Independent C header and initialized native attribute disagree | Correct alias; `DefaultRwlockConstant` |
| Guard-size setter takes a pointer instead of a size value | Typed prototype probe fails; native setter/getter returns the passed address as the size | `size_t` value; `GuardSizeSignature`, `GuardSizeRoundTrip` |
| Once callback uses Pascal register convention instead of cdecl | Cdecl callback initially fails compilation; native type probe also fails | Use existing `TInitOnceProc`; `OnceCallbackSignature` |
| Yield imports a non-default historical symbol | Updated nxtest suite cannot link against untouched binding: undefined `pthread_yield`; isolated original consumer confirms it | Import `sched_yield`, matching the C header redirect; `YieldCurrentThread` |
| Linux advertises obsolete LinuxThreads internals | Original consumers cannot link `pthread_kill_other_threads_np` or `__pthread_initialize`; native symbol/declaration probe disagrees | Remove those two unsupported Linux declarations; `LegacyEntryPointAvailability` |

Before the yield link regression was added, five native cases failed and three
controls passed; the separately run availability case adds one proven failure.
The final suite's yield case also provides an expected untouched-source link
failure. The final **10 cases pass with no failures/errors/skips**. Controls
compare fourteen native synchronization-record sizes and exercise mutexes,
conditions, rwlocks, semaphores, once, TLS and a one-participant barrier. No test
creates a worker thread. The apparent old barrier layout agrees in native size
on this host; it was not changed or claimed as a separate proven defect.

A raw dynamic lookup also fails to find `pthread_atfork`, but an actual native
link succeeds through libc's normal link support. It remains intact; absence
from dlsym alone was not treated as a broken binding. None of the removed names
has an ordinary maintained source consumer. The corresponding raw POSIX
signature corrections for guard size and once are applied in the Android
include; Android runtime behavior is not claimed as validated.

`Pthreads.nxpackage` builds the unit; identity `NXRP.Unix.Pthreads`. Embedded BSD
credits and advertising/non-endorsement conditions remain. The core RTL's
separate native bindings were not relocated or changed.

## Integration and verification

The original NexusFPC directory is removed; this destination is the sole
maintained provider. Source headers, namespace wrappers/maps and original
notices remain. `COPYING.FPC` and LGPL `COPYING.txt` accompany the package.
No dotted-unit conversion, FPCUnit bridge, compiler variant or bootstrap stage
was introduced. The native package recipe compiles ordinary NexusFPC units;
this is not a claim of publishing a shared runtime-package SDK artifact.

Both package catalogs register the package. All 50 affected/new recipes pass
native target-aware nxbuild planning. Metadata for all three packages, XML/GUI,
both catalogs and Lab Forge passes NexusScript validation. The inherited users
and iconv demonstrations have native Lab recipes and run from external working
directories. The XML and GUI descriptors declare their direct package inputs.

Affected consumer runs: fpGUI 569, FCL XML review 14 and behavior 36, database
behavior 943, FCL Base 425, Synapse 12 and OpenSSL 22 pass: **2,021 passing
consumer cases, zero failures/errors**. FCL Base retains the other migration's
one explicit `FCL-001` BoolToStr skip; this relocation does not claim to fix it.
The existing scalar/procedural binding changes have no ordinary external source
consumer requiring further call-site changes. The RTL's own private thread
bindings are a separate implementation and are unchanged.

Consumer recipes, test fixture search paths and the existing optional
post-bootstrap users installation now name the relocated providers. The Forge
compiler/RTL recipes and generation order are unchanged. No compiler rebuild or
SDK promotion was performed; native validation uses the configured matching
NexusFPC 3.3.1/RTL, Clang 18.1.3, glibc and OpenSSL 3.0.13 on Linux x86-64.

All 34 new cases pass again when compiled against the built package units with
package source search paths omitted. Untouched-source proofs and final outputs
are saved outside source at
`/media/kcollins/dev/worktree/unix-bindings-relocation` in `baseline-results.json`,
`entrypoint-results.json`, `final-results.json`, `compiled-consumer-results.json`,
`plan-results.json`, `metadata-results.json`, `integration-checks.json` and
`logs`. There are no stale active compiler-side paths or generated binaries,
units, libraries or logs in these three source packages. Scoped Python syntax
and repository whitespace checks pass. Other workers' pre-existing edits are
preserved; no commit or push was requested.

Limits: execution and C ABI checks cover native Linux x86-64. Windows, Apple,
Android and other CPU targets were not built or run. Original target selection
remains; preserved source alone is not cross-platform validation. The finite
suite does not exercise every low-level native API. Examples stay centralized
in Nexus Lab; no source/evidence archive or second maintained provider was added.
