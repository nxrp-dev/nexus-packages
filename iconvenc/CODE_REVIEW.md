# iconvenc relocation review

Reviewed 2026-10-18 before inherited implementation changes; final native
verification completed 2026-10-18. Baseline: NexusFPC
`4f78c6c072c538cb2514a0a8226d53bca982cdf0:packages/iconvenc`, Git tree
`58e855095d9727570086c1ac78507cf55953f405`. All 6 inherited files are
recorded in [review/baseline-hashes.json](review/baseline-hashes.json).
Untouched snapshot:
`/media/kcollins/dev/worktree/unix-bindings-relocation/untouched/iconvenc`.
Git preserves the original source/notices without a tracked duplicate archive.
See [central provenance](../../../ATTRIBUTIONS.md#unix-iconvenc).

The review covered static and dynamic units, their shared implementation and
namespace wrappers/map. The original demonstration stays in Nexus Lab
`examples/text/encoding`.

## Proven findings and fixes

| Finding | Untouched-source proof | Fix / direct nxtest case |
|---|---|---|
| Invalid input after a full output allocation decrements a zero remaining length and writes beyond the buffer's logical boundary | Both static and dynamic `InvalidByteAtBoundary` raise ERangeError | Reserve output space before the inherited byte-preserving invalid-input policy writes a byte |
| Failed dynamic replacement corrupts the working converter's entry points | `FailedLoadPreservesConverter` leaves missing function pointers after rejecting a deliberately incomplete library | Resolve an entire candidate API into locals; publish only after all symbols resolve |
| Rejected dynamic libraries retain a loader reference | `RejectedHandleClosed` finds the rejected library still loaded with RTLD_NOLOAD | Close failed candidates, balance successful replacements and close the owned handle at finalization |

Four original cases fail/error; twelve controls pass. The final **16 cases pass
with no failures/errors/skips**. Both providers cover empty input, expansion,
1,000 shrinking conversions, stateful output flush, malformed input, incomplete
sequences and unknown encodings. The incomplete loader fixture is intentionally
linked without libc dependencies so libc cannot accidentally satisfy its
missing symbols. The exact native runner also supports isolated cases.

The initial pointer-after-trim/double-flush suspicion was not independently
reproduced by the shrinking/stateful controls, and is not counted as another
proven bug. The coherent conversion repair keeps growth and flushing before the
single final trim and limits `finally` to closing the converter; it removes the
unnecessary post-trim conversion. Failed opens retain their original input.
Dynamic initialization is idempotent; candidate resolution has explicit
sequential control flow rather than side-effectful Boolean alternatives.

`Iconv.nxpackage` builds both units; identity `NXRP.Unix.Iconv`. Low-level
`size_t/cint` ABI declarations remain. Linux uses libc iconv; inherited static
non-Linux library declarations and dynamic default library choices are retained
without claiming target validation.

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
