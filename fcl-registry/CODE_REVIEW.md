# FCL Registry relocation review

Reviewed 2026-10-17 before implementation changes. Source: NexusFPC
`86b61cc9dd212d58802a77383f6264bd2de1f9a5`, `packages/fcl-registry`.
The untouched 15-file snapshot and SHA-256 inventory are in Nexus
`output/fcl-registry-review/baseline` and `baseline-hashes.json`.
The review covers registry.pas, xmlreg.pas, the native Windows/XML/INI includes,
namespace wrappers and retained tests. Proven results and limits follow below.

## Consumers and role

Windows consumers include NexusFPC `winunits-base/src/comobj.pas`, Abbrevia's
ZIP extractor integration, and Synapse's serial-port implementation. The latter
two imports are conditional Windows code. The package provides native Windows
registry access; other targets use the XML emulation. Lab contains registry,
Unicode and remote-registry demonstrations, plus runtime/base examples using
both runtime units. Compiler test inputs also import Registry.

The retained package has a concrete OS integration purpose. This relocation does
not turn XML registry emulation into a new Nexus configuration architecture.
Examples stay centralized in Lab and test-only fixtures stay with their tests.

## Findings recorded before implementation

| ID | Location | Actual failure and regression |
| --- | --- | --- |
| R01 | xmlreg.pas, FindKey/CreateKey/SetKey | Absolute queries and creation clear the active element, and a failed absolute SetKey loses the old selection. Verify key probes/creation/failed open preserve the current key and subsequent writes. Also retain a control that deleting the selected subtree invalidates it. |
| R02 | xmlreg.pas, GetValueInfo/GetKeyInfo | Unicode metadata doubles binary/multistring sizes, QWord size is never assigned, and maximum value size misses several types. Verify byte counts for binary, multistring and QWord values and maximum data length. |
| R03 | xmlreg.pas, DoSetValueData | String writes ignore DataSize and scan until a trailing null outside the requested buffer. Verify bounded ANSI and Unicode writes using a larger buffer containing a deliberate suffix. |
| R04 | xmlreg.pas, DoGetValueData/HexToBuf | Invalid hex is reported as success with a negative size, and odd-length hex is silently truncated. Verify failed reads for malformed binary text. |
| R05 | xmlreg.pas, DoGetValueData/GetValueInfo | Negative/invalid type attributes are accepted or cast to an invalid enumeration, with uninitialized metadata. Verify rejection of negative, out-of-range and nonnumeric types. |
| R06 | regini.inc, WriteDate/WriteDateTime/WriteTime/WriteFloat | Finally blocks close the base key instead of restoring the saved section, breaking following operations. Verify base path/current key and subsequent section reads after each typed write. |
| R07 | registry.pas, ReadStringArray | Stripping an all-null MULTI_SZ buffer decrements the index past zero. Verify a valid empty, null-terminated multistring under bounds checks. |
| R08 | xregreg.inc, RegistryConnect | The XML backend reports successful remote registry connection without connecting anywhere. Verify an unsupported remote target returns failure. |
| R09 | xmlreg.pas, LoadFromStream | Parse errors are swallowed and existing state is replaced by an empty document, allowing a later write to overwrite malformed input silently. Verify malformed input raises and failed reload preserves the existing in-memory registry. |
| R10 | xmlreg.pas, GetKeyInfo | The one-argument FileAge returns an encoded filesystem timestamp, which is assigned directly to TDateTime. Verify key metadata matches the TDateTime output overload after flushing a file. |

Known explicitly unimplemented key import/export/move and binary-stream methods
are retained as existing scope limits, rather than adding new functionality in
this relocation. Native Windows behavior cannot be run on the Linux host; native
Windows checks and dotted-unit builds will be reported separately from the
portable/XML regressions. Delphi is unsupported.

## Consumer integration finding (recorded before its fix)

R11: Lab `examples/runtime/base/txmlreg.pas` and `testreg.pas` omit a Unix
Unicode-string manager. Both compiled with NexusFPC but exited 217 with
`ENoWideStringSupport` during the first registry string conversion. Their sibling
Unicode demos already install `cwstring`. Add the same conditional consumer
import to the two base demos. Four direct nxtest example checks exercise actual
Lab executables, rejecting unsuccessful exits and diagnostic failures. The
runtime package's unit tests remain independent of a Lab checkout.

## Proven failures and fixes

All ten package findings were proven with direct nxtest cases against the
untouched runtime source before its implementation changed. Bounds checks were
enabled. The same updated test harness/cleanup isolation was used for the
baseline and destination, rather than changing assertions between runs.

| Finding | Direct nxtest cases | Untouched source | Corrected source |
| --- | --- | --- | --- |
| R01 | key-probe, key-create, key-failed-open | 3 failures: selected element lost | 3 passed |
| R02 | size-binary, size-multi, size-qword, size-maximum | 4 failures: wrong/unassigned byte count | 4 passed |
| R03 | bounded-ansi, bounded-unicode | 2 failures: suffix beyond DataSize included | 2 passed |
| R04 | invalid-hex, odd-hex | 2 failures: malformed bytes reported as success | 2 passed |
| R05 | negative-type, large-type, nonnumeric-type | 3 failures: invalid type accepted by read or metadata | 3 passed |
| R06 | ini-date, ini-datetime, ini-time, ini-float | 4 failures: base key closed | 4 passed |
| R07 | empty-multi | Range-check error stripping all-null data | Passed |
| R08 | unsupported-remote | Unsupported connection reported success | Passed |
| R09 | malformed-load, failed-reload | 2 failures: malformed XML accepted silently | 2 passed |
| R10 | key-timestamp | Encoded FileAge value used as TDateTime | Passed |
| R11 (Lab consumers) | FCLRegistryExamples.xml, .registry | 2 failures, exit 217 / ENoWideStringSupport | 2 passed |

R01 now uses local traversal state, publishing selection only on successful
SetKey. Deleting the selected key or an ancestor clears the selection before
freeing the detached DOM subtree; the deletion control passed before and after.
R02 uses per-type byte sizes and shares that calculation with key metadata.
R03 copies only the provided ANSI/Unicode byte range. R04 rejects odd hex and
propagates decoding failure. R05 validates both enum bounds and numeric syntax
before casting. R06 restores the INI section with CloseSection in all four
finally blocks. R07 stops null stripping at zero. R08 returns False for the
unsupported XML remote connection. R09 parses into a temporary owned document,
re-raises errors and keeps the old document/selection on failed reload. R10 uses
the TDateTime output overload. R11 installs cwstring in the two Unix consumers;
the runtime does not take over its applications' string-manager ownership.

## Results and integration

Verified on **x86_64 Linux**, NexusFPC 3.3.1 identity
`778927a6beede09df345f5e9ee5e95f500b4f838-work-95622f1b76`, matching installed
compiler/RTL, using Nexus nxbuild. No Lazarus or system FPC was used.

| Check | Before | After |
| --- | --- | --- |
| Package nxtest suite | 10 passed, 23 failed, 0 errors/skips | **33 passed, 0 failed/errors/skips** |
| Nine retained nxtest cases | All passed | All passed; none removed |
| Selected-key deletion control | Passed | Passed |
| Original standalone tregistry2 | Exit 0 | Exit 0 |
| Four Lab example nxtest checks | 2 passed, 2 failed | **4 passed, 0 failed/errors/skips** |
| Production FCLRegistry.nxpackage, without test-only defines | — | Built xmlreg and registry |
| Portable Lab RegistryExamples.nxproject | Two examples failed at runtime | Four executables built and passed |
| Language-server search-path unit | — | Compiled after path update |
| Synapse synaser unit | — | Compiled on Linux |
| Abbrevia.ZipExtractor unit | — | Compiled on Linux; Windows body excluded |
| Compiler tregistry1 fixture | — | Compiled and exited 0 using isolated XML storage |
| Descriptor and both catalogs | — | NexusScript compilation/schema validation passed |
| Nexus Lab Forge registry build registration | — | NexusScript compilation/schema validation passed |

The nine retained cases cover small DWORD/string/binary buffers, basic registry
writes/replacement, the existing bug16395 behavior, string lists, Int64 and subtree
deletion. The original standalone program retains its wider TRegIniFile and
TRegistryIniFile section/path behavior. Its historical Delphi-mode directive is
compiled by NexusFPC; no Delphi compiler check is implied or required.

The test recipe enables `-Cr` and `XMLRegfile_in_CurDir`. Runner and child-case
working directories live in generated output, and retained cleanup helpers use
the same local file location. This avoids deleting application configuration
files. The production package build does not enable that define. The separate
example checker consumes built Lab executables, so the package unit suite does
not gain a Lab dependency.

Both package catalogs now register `NXRP.FCLRegistry`. Language-server defaults
and the distributed search-path JSON, Abbrevia's test and Lab build recipes,
and NexusFPC's package requirements record point to the new owner. Lab's Forge
group registers the portable registry recipe. Existing demonstrations remain
centralized in Lab. All 15 files disappeared from the former NexusFPC package
directory after snapshot/hash verification; this is a move, not a second copy.
Six original files remain byte-identical at destination. Four runtime files and
five runner/recipe/helper/documentation files have the intentional changes
recorded here. Namespace wrappers, regdef.inc, winreg.inc, the XML small-buffer
tests and copied distribution licenses are retained unchanged.

### Explicit verification limits

- Native Windows registry APIs, Windows COM consumers, the Windows sections of
  Synapse/Abbrevia and Windows compiler fixtures were not built or run. Only a
  Linux NexusFPC toolchain is installed. Linux conditional-unit compilation
  does not validate those Windows bodies.
- Lab remotereg needs Windows/JWA bindings and a remote registry service. An
  initial Linux build correctly could not resolve JwaWinNetWk; it is excluded
  from the portable recipe and was not launched.
- Abbrevia's registered runtime-package test build was attempted and fails at
  `Can't find package nxrtl`. The configured matching Linux package SDK is
  absent. This is an unresolved SDK prerequisite, not a passing consumer check;
  the source-level ZIP-association unit compiled separately as stated above.
- Dotted-unit wrapper builds and other target platforms were not executed.
- Existing explicitly unimplemented import/export/move and binary-stream APIs
  remain outside this relocation; no new implementation is claimed.

### Reproduction and local evidence

Build/run commands are in tests/NXTEST.md and README.md. The baseline recipe used
the snapshot's src path with the same destination regression sources, `-Cr` and
local-XML define. Generated-only records are under Nexus
`output/fcl-registry-review`: `baseline-build.log`, `baseline-results.log`,
`baseline-standalone.log`, `final-build.log`, `final-results.log`,
`final-standalone.log`, `package-build.log`, `example-baseline-results.log`,
`example-final-results.log`, `lab-example-build.log`, consumer build/run records,
schema-validation results and the Abbrevia prerequisite failure log. Corrected
Lab executables are under Lab `output/RegistryExamples/x86_64-linux`. No source
or evidence archive is added to the repository.

## Untouched source SHA-256 inventory

These hashes identify the source before this relocation's implementation fixes.
The original package tree is also recoverable from the reviewed NexusFPC revision
recorded at the top of this review. Canonical author/license/provenance information
is in [Nexus attributions](../../../ATTRIBUTIONS.md#fcl-registry).

| Original relative path | SHA-256 |
| --- | --- |
| `namespaced/System.Registry.pas` | `38c06b31b24ab7706dc60ebeb5adee5021f7892cb716390a74d8edc307adc81e` |
| `namespaced/System.Xmlreg.pas` | `d8536564e54a3f02ea25bfc6454f6dcd669c00ed13cdece930954f5c0c6ed584` |
| `namespaces.lst` | `783d6b032a3374d1cb49b3f7e02c6bd7eaa7743ce87a69717c017e048a670128` |
| `src/regdef.inc` | `725955c344c8230ecfa4ac8752eb5db1055402543199531d94fd95b67755a456` |
| `src/regini.inc` | `32cc7e24a93947fba5176df47885c0807040a4f74a777451b7b0a54d99370db1` |
| `src/registry.pas` | `0c51fbbae2bf19016cbb38f9acd2fd5d3ba45bf42e1dc36fb1931223c90549c2` |
| `src/winreg.inc` | `d131449ea9f37e845ba8566b05544f7e93b15888dad814e073b83ccf0dc58f90` |
| `src/xmlreg.pas` | `64755e4278132896988d61b94faeb9770f8da0db5524e617581925ae0a1d24c9` |
| `src/xregreg.inc` | `8721e0b75ec323d74eed6acad3ea756360a406183260c61c68adfca8715169a8` |
| `tests/FCLRegistryTests.lpr` | `2804a0934e3ccd7249dec395b9d6fe17eabdfc672f361ab24d11a0da04491ebd` |
| `tests/FCLRegistryTests.nxproject` | `ecbd5a5ff63f3f58675d1585fc4b03f486704be1be45e369a8f5c681d879e790` |
| `tests/NXTEST.md` | `6211446e74d0ea0d20670f13d8375df3ec3240dcf152049998670e65d34229d2` |
| `tests/regtcxmlreg.pas` | `fa40304e86fb13834099e2ccf55bbcc64c6ab5b79b23ad518a3d0f09a01f2b85` |
| `tests/regtestbasics.pas` | `98e564e8f0bf4e09b7cfd8289064b5f4155b4c0afddf2d07b99acc9053dd1bb0` |
| `tests/tregistry2.pas` | `578145250c08daecf09a780bb7592c6a90bdb549024b603c23311f16766dbb4d` |
