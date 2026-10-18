# FCL Res relocation review

Reviewed 2026-10-18 before changing inherited implementation. Authorized by
“move fcl-res next”, following the standard package relocation workflow.

## Baseline and ownership

The untouched source is NexusFPC `packages/fcl-res` at revision
`809ba610ddd2de4af75d6e7e372ac5a03efb270b`, Git tree `dfeac8afcaaeccd0e103ad3af93975c52372928f`.
All 59 source/include/namespace files are hashed in
`review/baseline-hashes.json`. An untouched verification copy is in ignored
`output/fcl-res-review/untouched`; the immutable Git tree preserves the baseline
without a second maintained provider or a checked-in evidence archive.

The reviewed scope includes the resource descriptors/tree/factory, cached data
streams, RES/COFF/PE/ELF/Mach-O/DFM readers, bitmap/icon/cursor models, version
models and FileInfo. Namespace wrappers must move unchanged with their sources.
Existing license headers and the FPC license/exception accompany the package.
Provenance belongs in [Nexus ATTRIBUTIONS.md](../../../ATTRIBUTIONS.md#fcl-res).

Setup is the production consumer: executable version comparison controls file
replacement and same-version repair. Resource-format tests and the Lab resource
example also consume these units. SynCommons has a disabled optional version
reader. No compiler or compiler utility imports were found. Forge release-tools
staging/search paths contain an unused fcl-res entry; remove those entries rather
than staging a second copy. The compiler bootstrap/build stages remain unchanged.

## Findings requiring regression proof

1. **Version parsing:** `TryStrToVersionQuad` replaces its parsing result with a
   dot count and narrows unchecked integers to Word. Invalid/extra/negative or
   oversized components can be accepted or raise errors in the Try function.
2. **FileInfo refresh:** `TFileVersionInfo.ReadFileInfo` appends results on each
   enabled property change and indexes an empty string-table list when no strings
   exist. The integer-indexed value accessor resolves correctly in the baseline;
   it is not a separate defect. Prove ordinary reads,
   repeated reads, filtering, missing translations and fixed-info-only files.
3. **Object string table append:** `TObjectStringTable.Add` writes at the current
   cursor left by `Get`, overwriting existing entries.
4. **Missing resource removal:** description-based `TResources.Remove` dereferences
   a nil result instead of reporting the resource-not-found error.
5. **Reader probe lifecycle:** both `FindReader` overloads lose the input cursor
   and leak the temporary reader when a probe raises. Short input must allow the
   remaining readers to be considered; unrelated exceptions must still propagate.
6. **Detached cached resource lifetime:** moving/removing cached resources can
   leave them dependent on a stream owned by the previous collection. Detach the
   data while that owner is still alive; prove payload survival after its removal.
7. **Truncated RES acceptance:** partial record headers and missing payloads can
   be treated as successful EOF; identifier parsing does not honor header bounds.
8. **Version block parsing:** translation handling retains one block header while
   consuming subsequent headers as values; root signature and declared lengths
   are not validated. Prove multiple translations and malformed fixed blocks.
9. **Mach-O fat selection:** bestCompatibility is never updated, so a later
   inferior slice replaces a better match; architecture table reads are unchecked.
10. **256-pixel cursors:** CUR directory zero dimensions mean 256, but conversion
    treats them as zero; reverse conversion narrows 256 to Byte in checked builds.
11. **Extended bitmap headers:** BI_BITFIELDS masks embedded in extended DIB
    headers are counted a second time when synthesizing the BMP pixel offset.

Only reproduced findings receive implementation fixes. Regression cases will
run directly through nxtest, without FPCUnit helpers or a bridge. Existing useful
compiler resource-format checks remain with their compiler fixtures and are
updated to resolve the relocated owner. Examples remain centralized in Lab.

## Baseline proof and fixes

The **same 23 direct nxtest cases** compile against the untouched hash-verified
snapshot and the relocated source. Baseline: **3 passed, 12 failed, 8 errors,
zero skipped**. Final: **23 passed, zero failures/errors/skips**. Both builds use
native NexusFPC, nxbuild, range/overflow checks and separate unit directories.
The three unchanged controls cover valid version quads, ordinary string-version
reading and a final RES payload without trailing alignment bytes.

| Finding | Baseline proof | Correction |
| --- | --- | --- |
| Version parsing | `InvalidVersionQuad` accepts `1.2.bad.4` | Require four decimal components in Word range and preserve parse failure; reject extra/missing components, signs, hex, spaces and oversized values |
| FileInfo refresh | `VersionRefresh` duplicates prior entries; `FixedOnlyVersion` raises EListError | Clear before each refresh, select/fallback deliberately, return an empty string set for fixed-only files, report explicitly required missing translations |
| String table append | `ObjectStringAppend` loses the second string after reading the first | Append at the data stream end regardless of the read cursor |
| Missing removal | `MissingRemove` raises EObjectCheck through a nil result | Use the existing resource-not-found lookup before removal, for both descriptor overloads |
| Probe lifecycle | `ProbeCleanup` loses the cursor; `ShortProbe` leaks EReadError out of format detection | Restore the cursor and free unsuccessful probes with finally; treat short reads as no match while propagating unrelated errors |
| Cached lifetime | `RemoveLifetime` and `MoveLifetime` raise EObjectCheck when reading after the old collection is freed | Materialize cached bytes before detaching from their owning collection; actual post-destruction payload reads pass |
| RES validation | `TruncatedPayload` and `PartialHeader` wrongly succeed; `HeaderBounds` raises ERangeError | Bound headers/identifiers/payloads and distinguish clean EOF from partial records; preserve unpadded final payloads |
| Version blocks | `Translations` misreads later translation headers; `VersionSignature` accepts a bad fixed signature; `VersionLength` raises ERangeError | Parse each child block/translation value with its declared bounds, check the root/fixed signature, clean partially loaded models on failure |
| Mach-O selection/table | `FatSelection` chooses a later inferior slice; `FatShortRead` silently discards later entries; `FatEmpty` raises ERangeError | Retain the best compatibility rank, read the complete architecture table and validate table/slice extents; normal short stream reads are completed |
| Cursor dimensions | `Cursor256` stores zero resource dimensions | Decode zero CUR dimensions as 256, double resource height, encode 256 as zero when reconstructing CUR |
| BMP offset | `BitmapMasks` reports 134 instead of 122 for a 108-byte bitfield DIB | Add separate masks only for the 40-byte header; extended headers already contain them |

Exact baseline/final logs, temporary verification projects and command outputs
are under ignored `output/fcl-res-review`; `results.json` records the final
counts and limits. No FPCUnit bridge, old parallel test runner or tracked
source/evidence archive is introduced. Test data is generated in memory or in
unique temporary files removed by the tests.

## Completed relocation

The sole maintained source is `nexus-packages/fcl-res`. All **59 inherited files**
are present: **51 remain byte-identical**, including every namespace wrapper,
namespace map and include. Eight implementation files contain the proven fixes.
The old NexusFPC directory is removed. Original headers, `COPYING.FPC` and the
LGPL text accompany the package; attribution/provenance is centralized in the
root [ATTRIBUTIONS.md](../../../ATTRIBUTIONS.md#fcl-res).

`Package.nxscript`, `FCLRes.nxpackage` and `tests/FCLResTests.nxproject` provide
catalog metadata, all-unit compilation and direct regression coverage. The
workspace and repository catalogs register `NXRP.FCLRes`. Setup's application
and test recipes, five compiler resource-check scripts and the Lab resource
example resolve the new owner. The Lab Forge catalog registers its new recipe.
Examples and notices remain centralized in Lab. Historical compiler inventories
and previous work plans retain their original paths as historical evidence.

Unused fcl-res release-tools staging/search paths were removed. The compiler
itself and shipped utilities import none of these units; its bootstrap stages
and build sequence are unchanged. Existing unrelated compiler work was not
edited; concurrent changes to the naming inventory and other owner files were
left alone.

## Final native Linux verification

- **27/27 flat package units build** through `FCLRes.nxpackage`.
- **23/23 package nxtest cases pass**, with range/overflow checks; no skips.
- **24/24 Setup tests pass** and the complete Setup application links, using
  fresh isolated unit-output directories and the relocated source.
- The Lab resource tool builds, lists **10** imported sample resources and
  extracts a **1,761-byte valid XML manifest**. Its Forge catalog validates.
- Both package catalogs compile and validate with NexusScript.
- Existing `Run-NXFileInfoMetadataTests.sh` passes RES input and PE fixtures for
  **i386, x86_64 and aarch64**, including repeated version loads.
- Existing `Run-NXResourceTablesTests.sh` passes **104 layout checks**, readers
  for **five ELF objects and ten target images**, all ten version/reload pairs,
  and unsorted/malformed dynamic-relocation cases. Targets cover Linux, Android,
  macOS, iOS and simulators; generated images are inspected offline on Linux.
- Existing `Run-NXCompilerResourceEmitTests.sh` passes four x86_64 target layouts
  (Linux, Android, macOS and iOS simulator), emitted-object/image inspection and
  metadata-reader checks.
- Existing `Run-NXLinuxPackageResourceTests.sh` passes exact NXPL linking,
  source-hidden provider consumption and provider resource ownership. This uses
  the already available isolated native compiler and its matching PIC RTL from
  the prior bootstrap verification; no toolchain installation is changed.
- Active source/build-path audit finds no old compiler-package references, and
  `git diff --check` passes for the affected repositories.

These are native Linux builds/runs and offline format checks. Windows/macOS and
mobile native execution were not run. The PowerShell host-check source-path
update was not executed here; the equivalent native scripts passed. Namespace
wrappers/map are preserved byte-for-byte, but a separate dotted-RTL build was
not run. No compiler bootstrap rebuild is needed for this source-package move;
no bootstrap code or stages were changed.
