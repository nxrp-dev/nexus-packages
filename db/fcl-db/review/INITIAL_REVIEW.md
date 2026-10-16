# FCL DB code review

Initial review saved 2026-10-16 before implementation changes. Source:
NexusFPC `ca6b3976bf5417fd73251dcb9f39d9edcf48ea07`, `packages/fcl-db`.
All 199 original files are preserved with hashes and an archive under `review`.

The retained SQL scanner/parser/generator, SQL script and dictionary suites pass
943 tests before changes. The initial build identified obsolete IDE registration
units requiring Lazarus, alternative translation files that intentionally reuse
the dbf_str unit name, and a missing pthreads search path for the pool unit.
These are build classification/prerequisite issues, not database correctness
findings. They will be preserved and described in the package build.

## Findings to verify

| ID | Priority | Original source | Failure and regression |
|---|---|---|---|
| 01 | P1 | export/fpsimplejsonexport.pas:279 | JSON row separators use the pre-Next EOF state and object rows use semicolons, producing invalid JSON. Parse one/multiple/filtered rows in both formats. |
| 02 | P1 | export/fpsimplejsonexport.pas:169,264 | JSON control characters and exported names are not fully escaped. Verify escaped control values, column names and row names, then parse them. |
| 03 | P1 | export/fpdbexport.pas:616 | Integer formatting narrows all integer fields through AsInteger, losing Int64/LongWord data. Export boundary values with IntegerFormat. |
| 04 | P2 | export/fpcsvexport.pas:220 | Assign omits IgnoreOuterWhitespace. Verify settings assignment preserves behavior. |
| 05 | P1 | base/fieldmap.pas:594 | Destroy leaves the dataset AfterOpen callback pointing at the freed field map. Verify callback restoration and reopen after map destruction. |
| 06 | P1 | json/fpjsondataset.pas:368-429 | Numeric comparisons round fractional differences or narrow/subtract large integer differences. Locate exact floating, date/time and Int64 values. |
| 07 | P2 | json/fpjsondataset.pas:1345 | Locate searches only from the current record onward, missing earlier records. Locate backward from the last row. |
| 08 | P1 | json/fpjsondataset.pas:1138 | Bookmark validation/comparison use pointer addresses instead of stored row IDs. Verify captured/duplicate/deleted/nil bookmarks and ordering. |
| 09 | P1 | json/fpjsondataset.pas:474 | Comparer.Items getter recursively calls itself. Access a constructed comparer item in a bounded fixture. |
| 10 | P1 | json/fpjsondataset.pas:1194-1299 | Field copies ignore string buffer bounds, partially terminate wide strings, copy four bytes for 16-bit fields, and write padded wide strings into JSON. Check declared field buffers, guards and read/write round trips. |
| 11 | P2 | json/fpjsondataset.pas:1395 | Lookup overwrites its missing-value Null with Boolean False. Verify missing, single and multiple result values without moving the cursor. |
| 12 | P1 | base/bufdataset.pas:3409; memds/memds.pas:365 | Blob writes shrink existing storage and add to Size rather than extending to the maximum position; reads beyond EOF can use negative counts. Check overwrite, extension, gaps and EOF in both datasets. |
| 13 | P2 | sqldb/sqldbpool.pas:1311 | Pool constructor omits inherited Create(AOwner), so component ownership is not registered. Create a pool with an owner and verify automatic destruction. |
| 14 | P1 | base/bufdataset.pas:4435,4472 | Binary packet header writes and row-state reads ignore short transfers. Inject short output and truncate a packet before its row state. |
| 15 | P1 | export/fpsqlexport.pas:221 | Null fields are emitted as empty strings or scalar defaults instead of SQL NULL. Verify null and ordinary values in generated statements. |
| 16 | P2 | export/fpfixedexport.pas:478 | UTF16 mode writes through a text stream forced to UTF8. Check a non-ASCII header and two rows as actual UTF-16 data. |


Runtime proofs, corrections, retained-suite diagnostics, final consumer results
and limits will be saved here. Each finding gets an nxtest regression against
the untouched source before a production fix. No Delphi validation is required.
Provenance belongs in [root ATTRIBUTIONS.md](../../../../ATTRIBUTIONS.md#fcl-db).
