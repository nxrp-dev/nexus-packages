# users relocation review

Reviewed 2026-10-18 before inherited implementation changes; final native
verification completed 2026-10-18. Baseline: NexusFPC
`4f78c6c072c538cb2514a0a8226d53bca982cdf0:packages/users`, Git tree
`82f01255f9d6e3d32da06dc6c63c6dfb5c310cb1`. All 12 inherited files are
recorded in [review/baseline-hashes.json](review/baseline-hashes.json).
Untouched snapshot:
`/media/kcollins/dev/worktree/unix-bindings-relocation/untouched/users`.
Git preserves the original source/notices without a tracked duplicate archive.
See [central provenance](../../../ATTRIBUTIONS.md#unix-users).

The review covered all five runtime units, namespace wrappers/map and README.
The inherited demonstration remains in Nexus Lab `examples/system/users`.

## Proven findings and fixes

| Finding | Untouched-source proof | Fix / direct nxtest case |
|---|---|---|
| `GetUserGroup` discarded its result | Current-account lookup disagrees with the independently obtained primary group | Assign the return value; `UserGroupResult` |
| Linux shadow record used 32-bit fields for C long values | Native `sizeof/offsetof` disagrees; a synthetic entry returns the wrong minimum/day fields | Six `clong` fields and unsigned `culong` flag; `ShadowLayout`, `ShadowValues` |
| Linux `setgrent` declared a result although the C header returns void | Typed callback-overload probe identifies a function instead of a procedure | Linux procedure declaration; `GroupEnumerationSignature` |
| Linux advertised BSD-only `setgroupent` | Original consumer fails native linking; C symbol probe and Pascal declaration availability disagree | Restrict declaration to BSD; `GroupEntryPointAvailability` |

The original suite has five reproducible failed cases and three passing
controls. The final **8 cases pass with no failures/errors/skips**, covering
native passwd/group sizes, current-account roundtrips, enumeration, group
members and missing-account exceptions too. Synthetic shadow input avoids
reading or changing the system shadow database. The public lookup records still
borrow libc-managed storage; no new persistent ownership contract is claimed.
The optional `crypth` binding compiles and retains its native crypt dependency.

`Users.nxpackage` compiles all five units on Linux. Metadata identity:
`NXRP.Unix.Users`. All unchanged inherited material is byte-identical, including
namespace wrappers/map. The rewritten README links the original authors/license
history through the central attribution record.

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
