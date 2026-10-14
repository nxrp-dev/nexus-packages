# Nexus SQLite dataset

`TNXSQLiteDataSet` in `src/obNXSQLiteDataSet.pas` inherits directly from FPC
`TDataSet`. It uses this package's `SQLite3Dyn` binding and has no GUI or SQLDB
dependency. `TNXSQLiteConnection` owns the SQLite handle and transactions.

```pascal
lConnection := TNXSQLiteConnection.Create(nil);
lDataSet := TNXSQLiteDataSet.Create(nil);
try
  lConnection.LibraryName := 'path/to/sqlite3.dll';
  lConnection.DatabaseName := 'example.sqlite';
  lDataSet.Connection := lConnection;
  lDataSet.SQL.Text := 'SELECT id, name FROM people ORDER BY name';
  lDataSet.Open;

  lConnection.StartTransaction;
  lDataSet.Edit;
  lDataSet.FieldByName('name').AsUnicodeString := 'Changed';
  lDataSet.Post;
  lConnection.Commit;
finally
  lDataSet.Free;
  lConnection.Free;
end;
```

`Open` accepts one read-only result-producing statement. Named query parameters
use `:name` and `Params`/`ParamByName`. `ExecSQL` executes a non-result-producing
statement. Connection `Execute` serves the same purpose without a dataset.
SQL and identifier strings contain UTF-8, as in the surrounding Nexus framework.

## Storage and editing

The dataset materializes query results for bidirectional navigation. Each
successful `Post` or `Delete` writes to SQLite inside a savepoint, then reloads
the query. Defaults, triggers, SQL ordering and query membership are reflected
in the new snapshot. A failed write retains the edit and runs the normal
dataset error-event path. A successful post has no pending change log;
`UpdateStatus` returns `usUnmodified`.

Without an explicit transaction, releasing the write savepoint commits the
operation. `StartTransaction`/`Commit`/`Rollback` allow multiple operations in
one transaction. Commit posts outstanding dataset edits. Rollback cancels
outstanding edits and refreshes the connection's open datasets. Other open
datasets are independent snapshots; call `Refresh` to observe writes made
through another dataset or external SQL.

Automatic writes require a single source table, its complete primary key in
the result, and unique non-NULL keys. This includes composite primary keys and
`WITHOUT ROWID` tables. Queries without a usable identity remain read-only.
Keys are never inferred from field position. Generated columns are read-only.
Automatic update/delete predicates include original stored values to reject
stale writes. Every write must affect exactly one row.

For explicit mappings, set `UpdateTableName`, optionally `UpdateDatabaseName`,
and `KeyFields` (semicolon-separated result field names). `InsertSQL`,
`UpdateSQL`, and `DeleteSQL` provide caller-defined DML. Their named parameters
may reference `:NEW_field`, `:OLD_field`, `:field`, or query parameters. Insert
SQL should return generated keys through `RETURNING`, in `KeyFields` order.
Update SQL can also return keys. The dataset does not invent updates for
ambiguous joins.

Bookmarks belong to one dataset and one open session. Refresh and writes keep
bookmarks for rows with unchanged keys; editing a key retains that row's
bookmark. Deleted, filtered-out and closed-session bookmarks are invalid.
Refresh and writes recheck key uniqueness. If identity becomes ambiguous, the
dataset becomes read-only and prior bookmarks are invalidated.
`IndexFieldNames` provides local ordering with semicolon-separated field names
and optional `ASC`/`DESC`. Text uses SQLite binary ordering over UTF-8 bytes,
independent of the operating system locale. `Locate` respects the visible view;
`Lookup` does not move or post the current record. Index definitions separate
field names from descending fields. Provider default ordering and the dataset's
`GetIsIndexField` hook describe the explicit local index; SQL ordering is not
inferred from primary keys. `MasterSource` binds matching query parameters to
master fields and reloads the detail when the master changes.

## Fields, filtering and blobs

Integer declarations map to `ftLargeint`; real declarations to `ftFloat`;
decimal/numeric declarations to `ftFMTBcd`; date/time declarations to their
corresponding field types; bounded character declarations to `ftWideString`;
unbounded text to `ftWideMemo`; and blobs to `ftBlob`. Persistent fields or
explicit `FieldDefs` can select another compatible type. Untyped expressions
are inferred from the complete result; mixed storage classes require an
explicit field. SQLite's own affinity and numeric precision rules still apply.
Incompatible values and oversized fixed fields raise errors rather than
silently truncating data.

Timezone-free date and timestamp text preserves its stored calendar value;
reading it does not apply the machine's timezone offset.

FPC 3.2.2 exposes `TField.IsIndexField` but never populates its private flag or
calls the dataset's index-field hook. That inherited field property remains
false; use `IndexDefs` to inspect local ordering.

`Filter` uses SQLite predicate syntax, including `IS NULL`, `LIKE`, comparisons
and boolean operators. `foCaseInsensitive` applies SQLite `NOCASE` collation;
LIKE patterns are explicit SQL patterns, not implicit `*` matching.
`OnFilterRecord` can add Pascal filtering. `FindFirst`/`FindNext`/`FindPrior`/
`FindLast` can search the predicate while `Filtered` is false.

Automatically created `TNXSQLiteBlobField` and `TNXSQLiteMemoField` preserve
NULL versus empty values. Use those classes for persistent blob/memo fields
when that distinction is needed: FPC's standard `TBlobField.Clear` uses the
same empty write-stream operation as writing an empty value. Blob variants use
byte arrays. Wide-memo streams contain UTF-16; binary blob streams contain
unaltered bytes. Destroy writable streams before posting. Cancellation or
closing detaches streams; detached writable streams cannot publish changes.

SQLite library leases prevent unloading or replacing the library while
connections are open. Connections and datasets are synchronous and should be
used on their owning thread.

## Binding names

`src/bindings/sqlite3dyn.pas` is maintained directly. Callback declarations are
named for their documented operation: file close, sector size, locking,
virtual-table lifecycle, memory allocation, SQL functions, and FTS5 operations
each have their own types. Matching signatures do not establish a shared role.
The common operations of the two page-cache interfaces and the FTS5 token
callback still share declarations because their purposes match.

All 116 hashed callback declarations were replaced with 163 declarations by
purpose, including real definitions for SQLite's public callback typedefs.
679 API parameter names were clarified, including byte counts, column and
parameter indices, schema names, data ownership callbacks, and output pointers.
The official SQLite exported names, constants, and record members remain the
direct connection to the upstream reference header.

`PPAnsiChar` now consistently means `char**`, and `PPPAnsiChar` means `char***`.
The former duplicate pointer declaration and misleading fourth-level name were
removed. Each affected API retains its original pointer depth.

The checked-in `reference/sqlite3.h` supplies the naming evidence. Two arguments
not explained there were confirmed against upstream sources: the shadow-table
[name suffix](https://sqlite.org/vtab.html#the_xshadowname_method) and the
shared-memory map [extend flag](https://github.com/sqlite/sqlite/blob/master/src/os.c).
The deprecated memory-alarm interface retains anonymous arguments because the
header explicitly declines to document their meaning. Automatic extension
registration retains the signature intentionally erased by the C declaration;
its actual entry-point arguments are documented in the reference header.

The naming pass compared all 306 API signatures and all 196 fields of 23
records against the original binding, resolving callback definitions and
character-pointer depth. Calling conventions, variadic declarations, argument
and result types, record field order, and packing are unchanged. The constants,
exported variable declarations, loader, and implementation are unchanged.

## Building the package

`SQLite.nxpackage` is the nxbuild description. It runs two ordered builds:

1. LLVM compiles `native/sqlite3.c` into `sqlite3.dll` on Windows or
   `libsqlite3.so.0` on Linux.
2. NexusFPC compiles `SQLite.nxpk`, containing all six Pascal runtime units
   and requiring `nxrtl`, into `SQLite.nxpl` with embedded development metadata.

The package imports the same installation settings as Abbrevia from
`projects/nxbuild/nxbuild.environment.nxscript`. Configure that module for the
installed toolchain and matching runtime-package SDK. The package description
has no target-specific branches; the environment selects the tools and the
platform Clang configuration in `native` supplies the shared-library filename.

Run from the Nexus repository root on Windows:

```powershell
& ./output/nxbuild-next/x86_64-win64/nxbuild.exe /action=plan /project=packages/nexus-packages/db/sqlite/SQLite.nxpackage
& ./output/nxbuild-next/x86_64-win64/nxbuild.exe /action=build /project=packages/nexus-packages/db/sqlite/SQLite.nxpackage
```

Both libraries and the compiled Pascal units go to
`output/nxbuild-sqlite/x86_64-win64`; no compiler output is written into source
folders. This builds the C dependency from source and does not consume the older
DLL retained in `runtime/win64` for existing deployments.

`native/sqlite3.c` is the unmodified SQLite 3.53.4 amalgamation from
[the official source archive](https://www.sqlite.org/2026/sqlite-amalgamation-3530400.zip).
The former package location contained that archive, but it was absent from the
relocated tree. It was recovered on 2026-10-14; its `sqlite3.h` and `sqlite3ext.h`
match the existing `reference` headers byte for byte. The source SHA-256 is
`B1DD5D74EC7F29055A6684FA06FB3C2F6821C87DD38F9A458DFD2E8A1DB28189`.
Original upstream notices remain in the C source.

The LLVM definitions preserve the feature set reported by the previous Win64
runtime, including FTS3/FTS5, R-tree/geopoly, session/preupdate, column metadata,
math/percentile, carray, RBU and diagnostic virtual tables. SQLite's existing
thread-safety setting remains enabled. Recursive-trigger and auto-vacuum defaults
are left at their upstream values. The Windows linker uses the existing
`reference/sqlite3.def` export list. Linux uses PIC and its system libraries.

## Verification

The existing nxtest suite lives in `test`; its project consumes `SQLite.nxpl`
and `nxrtl.nxpl`. SQLite Pascal source directories are deliberately absent from
the test project's unit paths.

```powershell
& ./output/nxbuild-next/x86_64-win64/nxbuild.exe /action=build /project=packages/nexus-packages/db/sqlite/test/NXSQLiteTests.nxproject
Copy-Item ../tools/nexus-fpc/build/forge-bootstrap/package-sdk/packages/nxrtl.nxpl ./output/nxbuild-sqlite/x86_64-win64/
& ./output/nxbuild-sqlite/x86_64-win64/NXSQLiteTests.exe ./output/nxbuild-sqlite/x86_64-win64/sqlite3.dll
```

The copy places the SDK's matching shared RTL beside the executable for local
verification. Deploy `SQLite.nxpl`, the native SQLite library, and matching
`nxrtl.nxpl` with consumers. Supply `LibraryName` when the C library is outside
the operating system's library search path. The test runner accepts an explicit
C library path as its first argument; omission uses the binding's platform default.

On Linux, use the corresponding native nxbuild executable and paths under
`output/nxbuild-sqlite/x86_64-linux`, with `libsqlite3.so.0`. First configure the
native Linux package SDK and SDK identity in the shared environment module.

Verified on Win64 on 2026-10-14: **28 passed; 0 failures/errors/skips**, using the
newly LLVM-built C runtime through the compiled Pascal package. The executable's
import table confirms both package dependencies. The C library exports the same
378 symbols as the previous runtime. Range, overflow and I/O checks remain
enabled in the test executable. Linux and Win32 package execution were not run.

Executable-local heap tracing is not enabled in this shared-RTL test recipe:
`-gh` installs a replacement memory manager after package startup has already
allocated memory, and this SDK then reports an invalid memory block before the
suite starts. The successful run is not a heap-leak verification. The earlier
static FPC 3.2.2 run passed all 28 tests with heap checks and zero unfreed blocks;
that remains historical evidence, not a result of this package run.

`tsNXSQLiteBindingTests.pas` adds four NexusTest cases exercising SQLite's calls
into result-row, scalar, aggregate, window, commit, rollback, update, progress,
and FTS5 callbacks. It also verifies table-result pointer depth and function and
auxiliary-data destruction. The new tests were corrected to use `sqlite3_exec`
for result callbacks and one statement per connection `Execute` call.

Corrections made during implementation and verification:

- Implemented all four public `Find*` overrides and their `Found` state.
- Replaced locale-dependent text ordering and equality with binary comparisons.
- Bound master-supplied values in execution copies while preserving the master
  link's `Bound=False` flags; removed a redundant detail refresh before reopening.
- Removed host-timezone adjustments from timezone-free date parsing and used
  field-type conversion when comparing stored date text with edited dates.
- Implemented native/non-native scalar buffer conversion, including FPC's
  Currency-sized `TBCDField` layout.
- Stored booleans as SQLite integers `0` and `1`.
- Preserved UTF-8 SQL bytes instead of encoding SQL and metadata a second time.
- Corrected local index/provider metadata and the dataset's index-field hook.
- Revalidated row identity after refresh and writes, preventing ambiguous keys
  from sharing bookmark identities or remaining writable.
