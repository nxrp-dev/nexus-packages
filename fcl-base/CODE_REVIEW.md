# fcl-base relocation review

Initial review saved **2026-10-18 before implementation changes**; relocation and
native verification completed the same day. The baseline is NexusFPC
`4f78c6c072c538cb2514a0a8226d53bca982cdf0:packages/fcl-base`, including the current
working tree's direct nxtest migration and completed expression Boolean-text
correction. All **133 inherited files** are recorded in
[review/baseline-hashes.json](review/baseline-hashes.json). The untouched snapshot
is outside source at
`/media/kcollins/dev/worktree/fcl-base-relocation/untouched/fcl-base`; the initial
review is saved beside that evidence as `initial-review.md`. No duplicate source
archive or second maintained provider is checked in.

## Scope and baseline

The package has **45 Pascal runtime units**, platform includes, namespace
wrappers/map, text documentation and the native FCL Base tests. Review examined
dependencies and platform selection, stream contracts, cache ownership, codecs,
URI conversion, formatting, persistence and observer lifecycle, alongside the
existing expression, CSV, container, INI, template, watcher and atomic coverage.
This is targeted code review and regression coverage, not an exhaustive proof of
every inherited API or platform.

All 45 unchanged runtime units compiled before corrections. The retained suite
passed **426 cases, zero failures/errors/skips** before relocation. The new
review suite was then compiled against the untouched snapshot with range,
overflow, I/O and assertion checks. Each case ran in its own bounded process:
**20 cases failed/errored and 7 controls passed**. All 14 findings below therefore
have an actual untouched-source failure, rather than a speculative concern.

## Proven findings and corrections

| ID | Defect | Untouched-source evidence | Correction / direct nxtest cases |
|---|---|---|---|
| FCLB-001 | `nullstream.Write` leaves its result unset | Returned byte count disagrees with the requested write | Assign the accepted byte count; `NullWriteCount` |
| FCLB-002 | `nullstream.Seek` returns an unset result and subtracts end-relative offsets | A position-return case raises a range error; seeking backward from EOF is rejected | Return the new position and add end-relative offsets; `NullSeekReturn`, `NullSeekEnd` |
| FCLB-003 | Cache resizing keeps links into freed/reallocated storage and mishandles empty endpoints | Grow/shrink contain foreign pointers, zero retains dangling endpoints, and growing from zero raises a range error | Rebuild links by stable slot indices while preserving data/MRU order; handle empty lists; `CacheGrow`, `CacheShrink`, `CacheZero`, `CacheGrowEmpty` |
| FCLB-004 | ASCII85 encoder emits the wrong partial tuple digits, including abbreviated partial zero tuples | Independent encoder vectors disagree for a one-byte input | Count actual tuple bytes, emit the leading padded digits, reserve `z` for full zero tuples; `ASCII85EncodeVectors` |
| FCLB-005 | ASCII85 line wrapping overflows/truncates its seven-byte intermediate string | Width-one output violates the requested line width | Write encoded characters directly with bounded line wrapping; `ASCII85Wrap` |
| FCLB-007 | ASCII85 ring buffer rejects a legitimately full buffer | Writing exactly 1,024 bytes raises an assertion | Remove the incorrect unequal-cursor assertion; retain the pre-write capacity check; `ASCII85RingCapacity` |
| FCLB-009 | URI unescaping reads past incomplete escapes and accepts nonhex digits as zero | A trailing percent raises an incidental range error instead of a conversion error | Validate the two following hexadecimal digits before reading; reject malformed escapes with `EConvertError`; `URIMalformedEscapes` |
| FCLB-010 | Reused buffered-file pages expose old bytes in sparse gaps | A one-page cache writes its old `$A5` bytes into a hole beyond EOF | Zero the unread page remainder before writing; `BufferedSparseGap` |
| FCLB-011 | Formatting an empty string indexes its nonexistent first character | An empty write raises a range error in a checked build | Avoid the zero-length write; `EmptyFormatting` |
| FCLB-012 | Definition lists reuse the previous entry name when a later entry has no equals sign | An unnamed definition inherits `first` from the preceding entry | Reset the name for each definition; `DefinitionTerms` |
| FCLB-013 | Base64 MIME size scanning continues beyond the first padding marker | The reported size includes a long ignored suffix although decoding ends at the first padding | Initialize the scan character and terminate at padding; `Base64MIMESize` |
| FCLB-014 | RTTI string-list loading ignores an explicitly stored zero count | Loading a saved empty list leaves stale destination items | Distinguish absent count from explicit zero and assign the empty list; `StoredEmptyStrings` |
| FCLB-015 | Mediator value-list detachment calls an unassigned interface local | Clearing/replacing a value list raises an access violation | Detach through the actual previous list; `ValueListClear`, `ValueListReplace` |
| FCLB-016 | Gettext lookup divides by the optional MO hash table size | Valid hashless and empty catalogs raise division by zero | Return no translation for an empty catalog; scan entries when the optional hash table is absent; `HashlessCatalog`, `EmptyCatalog` |

The two discarded suspicions retain their original investigation numbers:
**FCLB-006** (ASCII85 final-tuple decoding) passed all independent vectors, and
**FCLB-008** (URI encoding) passed exact encoding and filename roundtrip checks.
Their implementations are unchanged. The other controls cover null reads,
ordinary Base64, nonempty stored lists and hashed catalogs. ASCII85 vectors are
30 small constants produced independently by Python's standard-library encoder;
this is not a new runtime dependency or a large extracted test corpus.

The final review suite passes **27/27**. The retained suite passes **426/426**:
**453 passing package cases, no failures, errors or skips**. Both suites also
build and pass with FCL Base source/include search paths omitted, consuming the
45-unit package build. Package NXU/object hashes remain unchanged during those
consumer builds. This verifies ordinary compiled-unit consumption; it does not
claim publication of a shared runtime-package SDK artifact.

## Relocation and integration

`packages/nexus-packages/fcl-base` is the sole maintained provider. Its old
NexusFPC directory is physically removed. All 133 inherited files are present;
**121 are byte-identical**, including Contnrs, the previously fixed expression
parser, all namespace wrappers/map and original test assertions. Ten runtime
files contain only the corrections above; the other two changed inherited files
are the suite recipe and current test guide. Original notices remain, with
`COPYING.FPC` and `COPYING.txt` added from NexusFPC. See
[central attribution and provenance](../../../ATTRIBUTIONS.md#fcl-base).

`Package.nxscript` declares `NXRP.FCLBase`; `FCLBase.nxpackage` compiles all 45
runtime units. Both package catalogs register it. Twelve package descriptors
now declare their direct FCL Base dependency. FCL Base records its Unix Pthreads
input; the existing compiler RTL/RTL-ObjPas source prerequisites remain.
Applications, tests, Lab recipes, saved and default Pascal search discovery,
current usage documentation and later release-tool staging name the relocated
provider. The unrelated historical reports retain their historical paths.

The stock seed, generators, compiler/RTL closure and three-generation bootstrap
sequence are unchanged. Only the existing later release-tools source-copy input
moves; no compiler variant, stage, hashing mechanism, general SysUtils change,
FGL provider, test bridge or product thread was introduced. Contnrs and the
existing flat/dotted selection rules remain intact.

Examples remain in Nexus Lab. Its native FCL Base recipe builds the existing
cache and ASCII85 encoder/decoder demonstrations, and Forge registers that
recipe. The cache demonstration runs successfully; the codec programs recover
all 263 bytes of a disposable binary sample, including every byte value and a
partial zero tuple. Other legacy demonstrations were preserved, not all executed.

## Final verification

- All **63 affected/new native nxbuild plans** pass. All **16 metadata/catalog/
  Lab Forge validations** pass. nxbuild itself was rebuilt against the relocated
  source and its **25 native cases** pass.
- Verified affected suites total **3,457 passing cases, zero failures/errors**,
  plus successful torrent and XMPP smoke programs. This consumer total excludes
  the 453 package cases and their repeated compiled-unit runs. Coverage includes
  GUI **569**, JSON review **14** and behavior **528**, XML **14 + 36**, database
  **16 + 943**, image **18 + 17**, process **11 + 23**, registry **33**, Synapse
  **12**, OpenSSL **22**, HashLib **26**, RTL-ObjPas **520**, collections **269**,
  compiler utilities **30**, compiler recompilation **30**, linker **10**, Forge
  **54**, Setup **24**, and RTL fixtures **213**.
- Consumer suites retain **22 existing skips**: three Windows process cases,
  one LF-only JSON formatting exclusion, one Unicode-default SDK requirement,
  and 17 recorded RTL platform/interactive/unresolved fixture exclusions. No
  package regression is skipped. JSON's three generated-code cases were rerun
  with the matching compiler/RTL configured and all pass.
- Forge/Setup test helpers now put generated work outside source. Forge uses
  its explicitly checked repository working directory for fixtures; its compiler
  probe selects the matching NexusFPC/RTL instead of silently running stock FPC
  and producing a `.ppu`. The existing optional-output assertions still run.
- NexusCSV, NexusForge and NexusSetup applications build successfully; the GUI
  application was compiled without launching it.
- The changed Pascal search-discovery unit compiles with its native dependency
  closure. Saved search-path JSON points to the same provider. There are **zero
  stale active compiler-side FCL Base paths** across the eight audited repos.
- Preservation checks, changed Python syntax and scoped whitespace checks pass.
  No binaries, compiler units, libraries, extracted data or logs were added to
  this package's source tree. All build/proof artifacts stay in the configured
  external worktree. Other workers' pre-existing changes remain intact.

## Limits and evidence

Execution covers native Linux x86-64 with the configured matching NexusFPC 3.3.1
SDK, Clang 18 and system OpenSSL 3. Windows, Apple, Android and other CPUs were
not executed. No compiler bootstrap/release matrix rebuild or SDK promotion was
performed. Existing platform conditionals were preserved; preservation is not
cross-platform execution evidence.

The unchanged, optional NexusScript and NexusScriptLS full-suite recipe files
still use the retired Windows-only nxbuild schema (`BuildTool`). Those two
legacy recipes were not migrated in this package relocation and their full
suites are not claimed as run. The shared compiler is exercised by the rebuilt
native build tools and current metadata validation. The old private GUI build
helper received its FCL Base source-path correction and syntax check; its other
legacy prerequisites were not reworked or executed.

Evidence root: `/media/kcollins/dev/worktree/fcl-base-relocation`. It contains
`baseline-hashes.json`, `baseline-review-results.json`, per-case `logs/before-*`,
`initial-final-results.json`, `final-native-results.json`,
`compiled-package-hashes.json`, `verified-consumers.json`, `plan-results.json`,
`metadata-results.json`, `integration-checks.json`, `application-builds.json`,
`final-source-hashes.json`, current logs, and the untouched snapshot. The
historical initial prerequisite failures remain in the raw logs; the verified
consumer summary uses their successful, correctly configured reruns.

No commit or push was requested.
