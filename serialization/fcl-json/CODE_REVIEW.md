# FCL JSON code review

Review date: 2026-10-15. Reviewed revision:
`5c10feaeb7d237a3658bee502f329e5765c1a1a7`.

The original static review identified eleven findings. All eleven have since
been reproduced and corrected on x86_64 Linux with NexusFPC 3.3.1. The original
descriptions and source locations below refer to the reviewed snapshot.

## Regression evidence and corrections

Verification date: 2026-10-15. One numbered nxtest case per finding is registered
in [tsFCLJSONTests.pas](tests/tsFCLJSONTests.pas). Before any corrections, the
source was copied to `output/fcl-json-tests/baseline-src` and its file hashes
were saved in `output/fcl-json-tests/before.json`.

**Untouched baseline:** 11 failed, 0 passed, 0 skipped.
**Corrected source:** 11 passed, 0 failed/errors, 0 skipped.

| Case suffix | Baseline evidence | Correction and coverage |
| --- | --- | --- |
| 01 IgnoredDuplicateContainers | Access violation while parsing an ignored duplicate object. | Retain ownership of ignored values until parsing finishes, including error paths. Covers objects, arrays, nested duplicates, retained first members and heap use over 32 malformed parses. |
| 02 DirtyConfigurationFilename | Switching files overwrote the destination's value. | Flush the old filename before assigning the new one; reopen both files and check their independent contents. |
| 03 IniWriteThrough | A write with caching disabled did not create the file. | Restore the cache setting, preserve the intended cached default, update through SetKeyData, and clear dirty state on a successful save to the backing file. Reopens disk without UpdateFile to verify strings and typed values, then checks deferred writes and the cache-to-write-through transition. |
| 04 UnexpectedColon | `[:]` was accepted. | Reject tokens that cannot start a value; malformed arrays and object values are checked with and without joStrict. |
| 05 StrictControlCharacters | Raw U+0014 was accepted. | Reject raw character codes below 32 in strict strings; all 32 controls and their valid Unicode escapes are checked. |
| 06 EmptyWriterDestruction | Range error on destroying an unused writer. | Check stack storage before freeing its root; also checks destruction after extracting data. |
| 07 UnsignedWriterRoundTrip | Range error when writing a value above High(Int64). | Add QWord value/property overloads and use the unsigned accessor. Both writers round-trip High(Int64), High(Int64)+1 and High(QWord). |
| 08 IntegerDifferenceDiagnostics | Formatting raised EConvertError. | Supply both Integer/Int64 values; format QWord values as unsigned decimal strings. Checks expected and actual values in each diagnostic. |
| 09 UnicodeCharacterRestoration | U+00E9 was restored as 195 instead of 233. | Decode AsUnicodeString before assigning WideChar/UnicodeChar ordinals; covers accented Latin, Greek and CJK characters. |
| 10 YamlStringRoundTrip | Independent YAML parsing rejected the generated document. | Quote and escape string values and property names. PyYAML round-trips Boolean/number/null-like strings, newlines, punctuation, quotes, backslashes, Unicode, sequences and nested typed values. |
| 11 GeneratedScalarClasses | With -gt, scalar-only classes acquired an unmatched destructor declaration. | Initialize the complex-array flag. The compilation probe also exposed a helper declaration left inside a type section for complex arrays with no load/save options; that type-section boundary is corrected. Twelve generated units compile across scalar/complex shapes and four load/save settings. |

The regression project enables range checking and `-gt` local-variable
initialization so the empty stack and uninitialized generator flag fail
deterministically on the baseline. The corrected suite also passes without
those instrumentation options. Fixture processes isolate memory failures and
enforce bounded waits. See [build and test instructions](tests/README.md).

The regular [package recipe](FCLJSON.nxpackage) compiles all 13 runtime units.
The nxbuild and NexusScript CLI consumers were rebuilt with the corrected JSON
sources. Neither Windows nor other targets have been executed in this pass.

The retained FPC suites were initially compiled and run against both snapshots:

| Suite | Baseline | Corrected |
| --- | --- | --- |
| testjson | 415 tests, 0 failures/errors, 1 existing Linux ignore | Same |
| testjsonconf | 9 tests, 0 failures/errors | Same |
| testjson2code | 85 tests, 8 failures, 0 errors | Same eight failure messages |
| tcjsonini | 29 tests, 1 failure, 0 errors | Same Boolean spelling failure (`True` versus `true`) |

These were failures in the retained Nexus snapshot, not verified failures in
current upstream FPC. The follow-up below resolves them. The INI AssertValue
helper explicitly calls UpdateFile, which masked the write-through defect;
the new regression deliberately reopens the file without that helper.

Logs, source hashes and the upstream comparison are under
`output/fcl-json-tests/`, including `baseline/results.txt`,
`x86_64-linux/results.txt` and `upstream-comparison.json`.

## Follow-up: nine retained-suite failures

Eight failures were invalid tests. The ninth, `TestArrayArrayProperty`, also
used an obsolete output snapshot, but compiling its generated unit exposed a
real defect. All nine snapshot tests were removed; executable nxtest coverage
replaces the native array and Boolean scenarios.

The generator assertions consumed lines in a fixed order and expected neither
the existing `ClearArray` helpers nor the owning class destructors. These
helpers are necessary: the replacement tests count live generated objects and
verify that freeing the parent releases every owned array element. A new
`type` section after a helper declaration is also valid and necessary Pascal.

| Removed test | Diagnosis and replacement |
| --- | --- |
| TestObjectArrayProperty | Invalid class-header position and missing destructor expectation. Case 12 compiles and runs object arrays with no load/save helpers and all three enabled combinations. |
| TestObjectArrayPropertySuffix | Same invalid layout assumption with a type suffix. Case 12 repeats the object-array checks with `PropertyTypeSuffix='Type'`. |
| TestArrayArrayProperty | Invalid class-header position **and a real compile error**: outer cleanup called `ClearArray` for a scalar array with no such overload. Case 13 fails before the fix and compiles/runs four load/save configurations afterward. |
| TestObjectArrayArrayProperty | Expected the next array declaration where a valid cleanup helper and new type section occur. Case 12 checks nested object-array values, saves and destruction. |
| TestLoadObjectArrayProperty | Expected the array creator where the cleanup declaration occurs; also omitted cleanup implementation and destructor. Case 12 executes the generated loader and verifies the loaded fields and ownership. |
| TestLoadDelphiObjectArrayProperty | Same invalid declaration order and omitted cleanup. Shared cleanup is exercised by the native case; the Delphi-specific loader was inspected but could not be compiled on this host. |
| TestSaveObjectArrayProperty | Expected the array saver where the cleanup declaration occurs; also omitted cleanup implementation and destructor. Case 12 executes generated saves and compares the result with the original parsed JSON. |
| TestSaveDelphiObjectArrayProperty | Same invalid declaration order and omitted cleanup. `TJSONArray.Add(TJSONObject)` is supported by the [documented Delphi API](https://docwiki.embarcadero.com/Libraries/Sydney/en/System.JSON.TJSONArray.Add); the generated Delphi unit was not compiled here. |
| TJSONIniTest.TestWriteBoolean | Invalid `True` string expectation: `TJSONBoolean.AsString` returns `true`, consistently with the existing Boolean data tests. Case 14 checks both Boolean types and lowercase spellings on disk, cached flushes, write-through and reopened values, including false. No implementation change was needed for this failure. |

Compiling a mixed object/scalar-array variant exposed a second real generator
bug: the owning class destructor called `ClearArray` on its scalar-array field,
although only the object-array overload existed. Case 12 independently failed
with this type mismatch before the correction.

The two corrections in [fpjsontopas.pas](src/fpjsontopas.pas) are local:

- Nested scalar-array cleanup uses `SetLength` at the scalar-array boundary;
  recursive `ClearArray` calls remain for nested structured elements.
- Owning class destructors call `ClearArray` only for arrays of structured
  elements. Pascal finalizes scalar-array fields automatically.

Both new generator cases fail against the saved pre-correction source. The
Boolean replacement passes before and after. The final verification on x86_64
Linux with NexusFPC 3.3.1 is:

| Suite | Final result |
| --- | --- |
| FCLJSON.Review | 14 passed, 0 failures/errors/skips |
| testjson | 415 tests, 0 failures/errors, 1 existing Linux ignore |
| testjson2code | 77 tests, 0 failures/errors |
| testjsonconf | 9 tests, 0 failures/errors |
| tcjsonini | 28 tests, 0 failures/errors |

The nxbuild test project and all 13 regular package units build successfully.
The generator regressions compile 36 units overall; 24 array programs also run
and verify values, applicable load/save behavior and object ownership. The
remaining 12 are the original scalar-class compilation matrix. No Delphi
compiler/JSON SDK or non-Linux execution was available for this pass.

Follow-up evidence is under `output/fcl-json-tests/`: `remaining-before/`
contains the source/test snapshot, hashes and the original generated units;
`remaining-probes-before/` records the two reproduced compile failures and the
passing Boolean replacement; `x86_64-linux/results.txt` and
`upstream-remaining-final/` contain final suite results. The earlier evidence
directories remain unchanged.

## Original findings

## 1 P1 Parsing duplicate containers uses freed memory

Source: [jsonparser.pas:154](src/jsonparser.pas#L154),
[jsonparser.pas:214](src/jsonparser.pas#L214).

With `joIgnoreDuplicates`, input such as `{"a":1,"a":{"x":2}}` frees the
second value in `NewValue`, but returns its pointer. `StartObject` then pushes
that freed object as the active parse structure. Duplicate arrays follow the
same path. Subsequent parsing accesses freed memory.

Suggested correction: consume ignored containers without using freed storage,
either retaining them until parsing finishes or skipping their contents safely.
Regression coverage should include duplicate objects and arrays and verify that
the first member remains intact. The existing duplicate-key test covers only
scalar values.

## 2 P1 Changing a dirty configuration filename overwrites the destination

Source: [jsonconf.pas:716](src/jsonconf.pas#L716),
[jsonconf.pas:181](src/jsonconf.pas#L181).

`DoSetFilename` assigns `FFilename` before calling `Flush`. Changing the filename
on a modified configuration therefore writes its current contents over the new
destination before `LoadFromFile` reads it. An existing destination configuration
loses its contents.

Suggested correction: flush against the old filename before switching the
active file. Verify with two existing files and unsaved changes in the first;
switching files must not overwrite the second.

## 3 P1 JSON INI writes can disappear

Source: [jsonini.pas:137](src/jsonini.pas#L137),
[jsonini.pas:88](src/jsonini.pas#L88),
[jsonini.pas:204](src/jsonini.pas#L204).

`WriteString`, `WriteInteger`, and the other setters call `SetKeyData`, which
changes memory and sets `FDirty` without calling `MaybeUpdateFile`.
`SetCacheUpdates` also never assigns `FCacheUpdates`. Consequently,
`CacheUpdates := False` does not provide write-through, and destruction discards
changes unless an explicit save or another operation has already written them.

Suggested correction: restore the cache setting and connect the write methods
to the update path. The existing `TestWriteString` and related tests expect
write-through after disabling caching; verify the resulting file by reopening it.

## 4 P2 Malformed JSON values are silently ignored

Source: [jsonreader.pas:248](src/jsonreader.pas#L248).

`DoParse` has no rejection case for an unexpected colon; its default branch does
nothing. Inputs such as `[:]` and `{"a"::}` therefore produce empty containers
instead of syntax errors, including with `joStrict`.

Suggested correction: reject every token that cannot begin a value. Add negative
tests for unexpected colons in arrays and object values in both parser modes.

## 5 P2 Strict strings accept some raw control characters

Source: [jsonscanner.pas:614](src/jsonscanner.pas#L614).

The scanner checks `Sp^ < #20`, where `#20` is decimal 20. Raw character codes
20 through 31 therefore pass through strict string parsing, even though they
require escaping in JSON.

Suggested correction: check the full control-character range below decimal 32.
Verify rejection of every unescaped control character and acceptance of its
corresponding valid escape.

## 6 P2 Destroying an unused data writer accesses an empty stack

Source: [jsonwriter.pas:323](src/jsonwriter.pas#L323).

`TJSONDataWriter.Create.Free` reaches `FreeAndNil(FStack[0])` before any write
has allocated the dynamic array. Empty writer destruction can consequently
raise an access violation or range error, including during exception cleanup.

Suggested correction: check whether the stack has storage before accessing its
root. Verify destruction before the first write and after extracting the data.

## 7 P2 The writer corrupts large unsigned integers

Source: [jsonwriter.pas:174](src/jsonwriter.pas#L174),
[fpjson.pas:1380](src/fpjson.pas#L1380).

The `ntQWord` writer branch reads `AsInt64`. Values above `High(Int64)` become
negative with range checking disabled; for example, `High(QWord)` is written as
`-1`. Range checking can instead raise an exception.

Suggested correction: provide an unsigned writer path without narrowing through
`Int64`. Verify exact round trips at `High(Int64)`, `High(Int64) + 1`, and
`High(QWord)`.

## 8 P2 Integer differences fail while formatting the diagnostic

Source: [jsoncomparer.pas:154](src/jsoncomparer.pas#L154).

The integer difference message requires two integer arguments. Each integer
branch instead supplies one Boolean expression. Comparing unequal integer
values therefore raises a formatting exception instead of reporting the
expected and actual values.

Suggested correction: supply both numeric values using the appropriate signed
or unsigned accessors. Verify unequal Integer, Int64, and QWord comparisons.

## 9 P2 RTTI restoration corrupts non ASCII characters

Source: [fpjsonrtti.pas:566](src/fpjsonrtti.pas#L566),
[fpjsonrtti.pas:587](src/fpjsonrtti.pas#L587).

The `tkWChar` and `tkUChar` branches take the first byte of a UTF-8 string rather
than decoding the character. For example, U+00E9 is restored as character code
`$C3`, its first UTF-8 byte.

Suggested correction: decode the character according to the target property
type before assigning its ordinal value. Verify non-ASCII character round trips.

## 10 P2 YAML conversion changes string values into other types

Source: [json2yaml.pas:77](src/json2yaml.pas#L77).

Strings are emitted without quoting or escaping. For example, JSON
`{"s":"true"}` becomes YAML `s: true`, changing the value from a string to a
Boolean. Embedded newlines can also change the document structure.

Suggested correction: quote and escape string scalars and property names as
needed. Verify that conversion preserves strings resembling Booleans, numbers,
or null, as well as strings containing newlines and YAML punctuation.

## 11 P2 Pascal generation reads an uninitialized flag

Source: [fpjsontopas.pas:558](src/fpjsontopas.pas#L558),
[fpjsontopas.pas:608](src/fpjsontopas.pas#L608).

`GenerateObjectDeclaration` initializes `HaveObj` but not `HaveComplexArr`.
The latter is only assigned when a complex array is encountered. For simpler
objects, its uninitialized value can cause a destructor declaration to be
emitted without the corresponding implementation.

Suggested correction: initialize `HaveComplexArr` before examining the members.
Verify that generated classes containing only scalar properties compile
consistently, alongside classes containing complex arrays.

## 2026-10-16 native retained-test conversion

Useful retained behavior tests now use nxtest directly. The former FPCUnit
helpers and runners were removed, with their originals preserved in hashed
archives. The [retirement report](../../../../docs/migrations/fpcunit/README.md) records conversions,
corrected invalid expectations, before/after results and verification limits.
