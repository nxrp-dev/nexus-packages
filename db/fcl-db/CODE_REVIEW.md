# FCL DB relocation and code review

Reviewed 2026-10-16 from NexusFPC revision
`ca6b3976bf5417fd73251dcb9f39d9edcf48ea07`, `packages/fcl-db`.
Destination: Nexus `packages/nexus-packages/db/fcl-db`.

**Result: 15 reproduced bugs fixed; 16 nxtest cases pass.** Candidate 03 was
disproved and remains a passing control. All 66 selected runtime units build;
943 retained FPCUnit tests and 28 SQLite consumer tests pass on x86_64 Linux
with NexusFPC 3.3.1. The original directory has been removed. Post-move builds,
all suites, SQLite and six compiler database regression programs pass.

## Preservation and scope

The [initial review](review/INITIAL_REVIEW.md) was saved before implementation
changes. Its claims were candidates, not verified conclusions. All **199**
original files are preserved byte-for-byte in
[baseline-source.tar.gz](review/baseline-source.tar.gz), with a
[per-file SHA-256 inventory](review/baseline-hashes.json) and
[archive checksum](review/baseline-source.tar.gz.sha256). The comparison runner
verifies those hashes before using the baseline. Exactly nine original runtime
files differ in the maintained copy; original examples, standalone programs,
namespace wrappers, translations, data and test sources remain present.

Original source notices are intact. `COPYING.FPC` and `COPYING.txt` were copied
from the source repository's package and RTL license texts. Authors, upstream
revision evidence, mixed notices and historical status are recorded in the
[canonical attribution record](../../../../ATTRIBUTIONS.md#fcl-db).

Review covered the retained database units: dataset and field-map behavior,
JSON datasets, memory/blob storage, packet streams, exporters, SQL parsing and
generation, dictionaries, DBF and SQLDB support. The findings below identify
specific reproduced defects; successful compilation is not an exhaustive
behavioral audit of every API or file format.

## Reproduced findings and corrections

IDs match `FCLDB.Review` in [tsFCLDBTests.pas](tests/tsFCLDBTests.pas).
Fixtures are in [obFCLDBProbe.pas](tests/obFCLDBProbe.pas). Source locations in
the initial review refer to the untouched snapshot.

| ID | Priority | Source and original failure | Correction and regression |
|---|---|---|---|
| 01 | P1 | `export/fpsimplejsonexport.pas`: row termination inspects EOF before advancing, producing a trailing comma; object rows use semicolons. The original array fails JSON parsing. | Emit commas before subsequent rows. Parse empty and multiple rows in array/object formats; the escaping fixture also parses a single object row. |
| 02 | P1 | Same exporter: control characters and exported field/row names are incompletely escaped. The original fails the control-byte assertion. | Use the existing JSON string escaping function for values and names. Check escaping and parse the resulting exports. |
| 04 | P2 | `export/fpcsvexport.pas`: settings assignment omits `IgnoreOuterWhitespace`. | Copy that setting; verify assignment preserves it. |
| 05 | P1 | `base/fieldmap.pas`: destruction leaves `AfterOpen` pointing at the freed map. | Restore the previous callback when the map still owns the installed handler. Verify callback restoration, reopening, and preservation of a later replacement handler. |
| 06 | P1 | `json/fpjsondataset.pas`: numeric comparers round fractional differences or subtract/narrow integer differences. Original floating lookup selects a different value. | Compare operands directly and return their ordering. Exercise nearby floats, six-hour date/time differences and Int64 values separated by 2^32. |
| 07 | P2 | Same dataset: `Locate` starts at the current record and misses earlier rows. | Search the complete current index. Locate backward from the last row. |
| 08 | P1 | Same dataset: bookmark validation and comparison treat the bookmark pointer as the row ID. A freshly captured bookmark is rejected. | Read the stored ID and resolve its position in the current index. Check captured, duplicate, ordered, deleted and nil bookmarks. |
| 09 | P1 | Same dataset: `TRecordComparer.Items` getter calls itself recursively. Original fixture terminates with process status 139. | Read the backing array. Verify a constructed comparer item in an isolated fixture with a deadline. |
| 10 | P1 | Same dataset: string copies exceed field buffers, wide terminators are incomplete, 16-bit fields copy four bytes, and wide writes include padded data. Original string copy overwrites a guard byte: expected 165, observed 101. | Bound output copies, write full terminators, use the correct scalar widths and read terminated wide input. Check byte guards, Unicode round trips, SmallInt and Word reads/writes. |
| 11 | P2 | Same dataset: an unsuccessful `Lookup` replaces Null with Boolean False. | Preserve Null on a miss. Verify missing and successful lookup behavior and cursor preservation. |
| 12 | P1 | `memds/memds.pas` and `base/bufdataset.pas`: an overwrite shrinks allocation while increasing recorded size. Writing two bytes into a six-byte blob reports eight bytes. Buffered storage also trips heap corruption during cleanup. | Grow only when the end position extends storage, preserve the suffix, zero gaps, and return zero at/past EOF. Exercise both implementations. Supplemental probe 112 isolates the buffered version: original exit 204, fixed exit 0. |
| 13 | P2 | `sqldb/sqldbpool.pas`: constructor omits inherited component construction and ignores the owner. | Call inherited `Create(AOwner)`; verify component registration and owner-driven destruction. |
| 14 | P1 | `base/bufdataset.pas`: packet signature writes ignore short transfers; row-state reads ignore missing input. Original output contains a damaged signature. | Use `WriteBuffer`/`ReadBuffer`. A short write must complete correctly or raise; absent row state must raise `EReadError`. |
| 15 | P1 | `export/fpsqlexport.pas`: a null string becomes an empty quoted string. | Return SQL `NULL` before formatting. Verify the generated null statement. |
| 16 | P2 | `export/fpfixedexport.pas`: UTF16 mode writes through a UTF8 text stream. Original starts with byte 195 instead of the UTF16LE BOM. | Write the BOM and UTF16LE code units directly to the export stream. Compare a non-ASCII header and two rows against exact UTF16 bytes. |

### Disproved candidate 03

The initial review claimed `FormatField` narrowed Int64 values through
`AsInteger`. Its actual `IntFieldTypes` set excludes the large integer field
types, which take the string conversion path. Exporting `High(Int64)` passes
against both versions. **`export/fpdbexport.pas` is unchanged.** The useful
boundary-value case remains as `03IntegerExportWidth`; it is not counted as a
bug or a fix.

## Proof and retained-suite diagnosis

| Check | Untouched source | Corrected source |
|---|---|---|
| 16 nxtest review cases | 1 passed, 15 failed; no errors/skips | 16 passed; no failures/errors/skips |
| Same cases without range/local-variable instrumentation | Original comparison available through `baseline-plain` | 16 passed; heap guards remain enabled |
| Buffered blob supplemental probe | Exit 204; heap corruption | Exit 0; passed |
| Scanner/parser/generator, SQL script and dictionary suites | 943 tests, 0 errors/failures | 943 tests, 0 errors/failures |
| Classified runtime units | 66 build successfully | 66 build successfully |

Saved outputs: [before regressions](review/evidence/before-regressions.txt),
[after regressions](review/evidence/after-regressions.txt),
[plain regressions](review/evidence/plain-regressions.txt),
[before retained suites](review/evidence/before-retained.txt),
[after retained suites](review/evidence/after-retained.txt),
[blob proof](review/evidence/blob-buffer-proof.json),
[original heap diagnostic](review/evidence/before-buffered-blob-heap.txt),
and [build results](review/evidence/after-builds.json).

The first compile inventory attempted 74 unit candidates. Two are obsolete
IDE registration units (`dbf_reg`, `tdbf_l`) requiring Lazarus; six are
alternative translations that deliberately declare the ordinary name
`dbf_str` (`es`, `fr`, `ita`, `nl`, `pl`, `pt`). These eight are preserved but
excluded from the runtime recipe. `dbf_str_ru` declares a distinct name and
does build. Seven additional `.pas` files under `src` are standalone programs,
not runtime units. The pool unit also needed the retained `pthreads` dependency
on its search path. The final classified inventory builds all 66 runtime units
against both source versions. These initial compile diagnostics were build
classification/prerequisite issues, not additional database bugs.

No useful retained test was deleted and no retained behavioral assertion was
weakened. The five original FPCUnit suites run through a new console wrapper;
obsolete GUI/resource runner dependencies are unnecessary. Earlier retained
runs printed extra `A` diagnostics equally before and after, with zero failures.
Two new-test assumptions were corrected during development: floating equality
uses an explicitly typed Double rather than comparing an Extended literal to a
Double; a partial stream write may be retried successfully by `WriteBuffer`,
so the test accepts either complete output or an explicit write error.

## Package and integration verification

- `Package.nxscript` registers `NXRP.Database.FCLDB`; both package catalogs
  reference it. Descriptor/catalog validation passes.
- `FCLDB.nxpackage` builds the 66 ordinary runtime units from ten explicit
  source roots. The source list is also saved in
  [runtime-units.json](review/runtime-units.json).
- `tests/FCLDBTests.nxproject` builds the isolated fixture and nxtest runner;
  `tests/FCLDBRetained.nxproject` builds the retained console suites. Both build
  and run successfully. Installed RTL paths precede the HeapTrc source fallback
  so special compiler bootstrap units are not accidentally rebuilt.
- SQLite's build recipe points to relocated `src/base`. A fresh source build
  against relocated DB passes all **28** SQLite tests with a native SQLite C
  library built by nxbuild. Its Unix test entry point now installs `cwstring`;
  without it the first run had missing WideString conversion failures. SQLite
  implementation code is unchanged.
- The language server defaults and saved IDE database templates use all ten
  relocated source roots. A compiled path-resolution probe verifies the defaults.
- Two compiler regression helper includes now point to the retained test units
  in Nexus. All six compiler database regression programs (`tdb1`–`tdb6`)
  compile and run successfully after removal of the original package directory.

See [SQLite results](review/evidence/sqlite-results.txt),
[consumer builds](review/evidence/consumer-builds.json),
[path results](review/evidence/search-path-results.txt),
[package build](review/evidence/package-build.log), and
[descriptor validation](review/evidence/descriptor-validation.json).
Reproduction commands are in [tests/README.md](tests/README.md).

The [post-move results](review/evidence/postmove-builds.json),
[post-move regressions](review/evidence/postmove-regressions.txt),
[post-move retained suites](review/evidence/postmove-retained.txt), and
[compiler consumer commands/results](review/evidence/compiler-consumers.json)
confirm that the old source directory is unnecessary. All 66 expected runtime
unit artifacts are present. The sibling patch removes exactly the 199 preserved
files and changes only its relocation checklist and two compiler-test includes;
concurrent compiler/resource work was left in place.

## Limits

Validation is native x86_64 Linux with the installed NexusFPC toolchain. Windows,
other cross targets, separate dotted-unit compilation, live SQLDB server
connections and exhaustive DBF/dialect coverage were not run. Previously
removed external SQLDB drivers were not restored. The original standalone
demonstration programs and GUI runner are preserved, not certified by the 943
console test count. The existing SQLite `.nxpk` SDK packaging stage was not run;
its native library and Pascal source consumer were built and tested. A full
compiler/bootstrap/release rebuild was not needed or performed. Delphi support
is outside Nexus scope.

## 2026-10-16 native retained-test conversion

Useful retained behavior tests now use nxtest directly. The former FPCUnit
helpers and runners were removed, with their originals preserved in hashed
archives. The [retirement report](../../../../projects/nxtest/retained/README.md) records conversions,
corrected invalid expectations, before/after results and verification limits.
