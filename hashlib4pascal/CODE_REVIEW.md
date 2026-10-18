# HashLib4Pascal source and integration review

Revision: `1687d81fd0c8a08f3f04e7fed507a19131fbc0b1`.
Reviewed before Nexus integration changes on 2026-10-17.

The selected upstream closure contains all 144 runtime units, all 135 include
files and the original MIT license/README. The pinned archive has no
`HashLib.Tests/Data` directory; useful inline vectors are adapted directly,
without inventing a fixture tree. Original source
bytes are recorded in `review/import-hashes.json`; no alternative implementation
or public wrapper is introduced. Provenance belongs to the
[central attribution record](../../../ATTRIBUTIONS.md#hashlib4pascal).

The review examined source dependencies, public digest/stream APIs, initialization,
factory algorithm coverage, conditional SIMD dispatch, disabled PPL support,
FPC minimum version and the upstream known-answer tests. HashLib is an ordinary
runtime/tool library; it must never enter NXPackageFile, compiler bootstrap or
PasZLib. PPL stays disabled and no product thread is added.

Integration constraints requiring verification are complete explicit unit/include
closure, SDK ownership of RTL support units, source-free package consumption,
managed return values across provider images, exact raw-byte/hex contracts and
default SIMD behavior. These are verification requirements, not proven source
bugs. No algorithm defect has been demonstrated by this source inspection.
Any subsequent compiler incompatibility or behavioral failure must be reproduced
against the original imported bytes before a localized fix is recorded here.

## Integration results, 2026-10-17

All 281 imported files (144 units, 135 includes, LICENSE and README) match the
pinned archive and `review/import-hashes.json` byte for byte. No upstream
algorithm implementation was changed. `HashLib4Pascal.nxpk` explicitly lists the
complete 144-unit runtime selection and requires the existing nxrtl foundation.
The three catalogs and both HashLib/Torrent descriptors pass NexusScript dialect
validation. Runtime source discovery has been added to the editor paths.

The first clean compile exposed an include-path omission: nested SIMD includes
resolve relative to `Simd/Backend`. Adding that directory alongside `Include`
fixes the build without modifying the original include tree. Source builds use
the native RTL plus explicit RTL Object Pascal/Generics, FCL Base and pthreads
support sources; no legacy hash, PasZLib, OpenSSL or FPCUnit path is used.

The direct nxtest suite compiles all 144 runtime units and passes **10 tests**:
MD2/MD4/MD5 RFC vectors; MD5/SHA-1/SHA-256 empty/abc inputs; HMAC SHA-1/SHA-256;
CRC32; binary lengths 1, 55, 56, 63, 64, 65, 127, 128 and 257; explicit UTF-8;
byte/untyped/file/stream APIs; incremental updates, clone and reset. Binary
SHA-1/SHA-256 expectations were independently generated with Python hashlib.
The RFC MD suites are retained directly in nxtest, without a test bridge.
Native NexusFPC 3.3.1, x86_64 Linux, default upstream SIMD settings: 10 passed,
zero failures/errors/skips. This is focused behavioral coverage, not a claim
that every imported algorithm has received a complete cryptographic audit.

## Proven consumer and compression findings

The ordinary-consumer migration uncovered two preexisting failures outside the
unchanged HashLib algorithms:

1. **Minizip signed CRC fields.** Checked ZIP writes and split reads fail when
   an intermediate CRC has bit 31 set; a stored one-byte-NUL ZIP also fails with
   final CRC `D202EF8D`. The untouched canonical PasZLib source reproduces
   `ERangeError` in `zip.pas`/`unzip.pas`. Direct nxtest
   `MiniZipInteroperability` and `MiniZipHighBitCRC` retain the cases. Running
   and stored CRC fields now use Cardinal; the existing four-byte reader's
   bit pattern is copied into the unsigned field. The same cases pass after
   the fix, including stored/deflated writes, independent ZIP input and CRC
   corruption rejection. PasZLib remains self-contained with private CRC32.
2. **MD demonstration false success.** The original Lab `mdtest.pas` returned
   success if any vector matched. Changing only the first expected MD2 value
   to an incorrect value still exits zero against the untouched driver.
   The corrected driver exits one at that vector. All 21 original RFC vectors
   remain in direct nxtest and the normal migrated demo exits zero.

The complete audit and per-consumer evidence are in the
[implementation review](../../../work/reviews/hashlib4pascal-package-and-hash-consumer-audit.md).

## Main-package consolidation follow-up

The owner subsequently directed relocation to main Nexus Packages and completion
of legacy hash removal. The entire package moved here with its review and original
notices; the External Packages copy is deleted. All 281 import hashes still match.
Catalogs, ordinary build recipes and editor paths now use this location.

In that pass, retained FPC RSA/ECDSA/PEM/OTP/UUID/NTLM services were migrated
to the Hlp API directly. The owner subsequently directed their complete removal,
including their dedicated tests and dependent Lab examples; both FPC package
directories are now retired. Final removal verification is recorded in the
[implementation review](../../../work/reviews/hashlib4pascal-package-and-hash-consumer-audit.md).
The superseded MD/SHA/HMAC/CRC/FNV sources, dotted wrappers, assembly includes,
obsolete runners and benchmark/fixture programs were deleted. No compatibility
facade or second hash implementation was added. Useful vectors remain in direct
nxtest: the fourteen RFC HMAC cases occupy 91 lines, without fixture classes.
The source/provider suite passes **26 cases**, compiling all 144 runtime units.

Before retirement, consumer regressions reproduced UUID variant-bit corruption
and ECC range-check failures in high-bit masks and byte serialization. The
migration corrected them and empty-key OTP, RSA hash/MGF1 and PEM thumbprint
checks. The then-retained crypto service suite passed **37 cases with -Cr**;
the unchanged baseline produced 29 passes, one failure and seven errors with
those same checks. These service tests were deleted with their implementations
by the subsequent owner direction. The original default-settings suites had
passed before migration.
The detailed before/after record is in the linked implementation review.

Compiler metadata and PasZLib remain independent. Only an obsolete legacy hash
input was removed from the native bootstrap helper; its build sequence is intact.

## Remaining verification limits

No usable native Linux runtime-package SDK exists in the configured native
installation or the scoped source/toolchain search. The Forge recipe validates
and stops at `PackageBuildPrepare` because `SDKDirectory` is empty. Consequently
there is no verified HashLib `.nxpl`, actual provider contained-unit inventory,
source-hidden ordinary/smart consumer run, or managed-value test across provider
images. Those checks require a matching SDK rebuilt for `NXPM0002`. They are
not replaced by source-mode results or by a disposable foundation image.

The existing compiler bootstrap/SDK Forge sequence was preserved. SDK assembly
is already post-bootstrap; its current producer is Win64-specific. Completing
that producer's Linux support and rebuilding a matching NXPM0002 compiler/SDK
remain separate verification work. The metadata codec and canonical compression
closure pass their focused source suites; these do not establish a runtime SDK.
No compiler variant, new stage, replacement metadata hash or SDK builder was
introduced. No unavailable platform is reported as passing.
