# RTL Unicode

`NXRP.RTLUnicode` restores FPC's Unicode collation tables, UTF-8 utilities,
grapheme enumeration, East Asian width properties and code-page maps. This is
the sole maintained source tree. Authors, original revision, source hashes and
licenses are recorded in the [central attribution](../../../ATTRIBUTIONS.md#rtl-unicode).
The [review](CODE_REVIEW.md) records reproduced failures and final verification.

ANSI remains the compiler default. Explicit `UnicodeString` and `WideString`
work in that mode. Unicode-default builds use the same package source with
`-MUNICODESTRINGS` and a matching RTL. PPUs from the two modes are not
interchangeable. The package does not participate in compiler bootstrap.

## Building and testing

Set `RTLUnicode.Build.Config.nxscript` to the selected compiler, matching RTL,
text mode and output directory. The default takes the native ANSI compiler/RTL
from the Nexus environment. The RTL must include this restoration's
`unicodedata.PrepareCollation` upper-bound correction; verification used rebuilt
RTLs in isolated output directories rather than modifying an installed SDK.

From the Nexus root on native Linux:

```sh
output/nxbuild-next/x86_64-linux/nxbuild /action=build /project=packages/nexus-packages/rtl-unicode/RTLUnicode.nxpackage
output/nxbuild-next/x86_64-linux/nxbuild /action=build /project=packages/nexus-packages/rtl-unicode/tests/RTLUnicodeTests.nxproject
cp packages/nexus-packages/rtl-unicode/tests/data/Unicode17.zip output/rtl-unicode/ansi/tests/
output/rtl-unicode/ansi/tests/RTLUnicodeTests
```

For Unicode defaults choose `TextMode: "UNICODESTRINGS"`, the corresponding RTL
path, and a separate output directory. The runner supports a single test ID as
its optional argument, for example `RTLUnicode.EmojiZWJ`.

The 19 direct nxtest cases cover default text widths, explicit Unicode/WideString
use, UTF-8 byte encoding/replacement/conversion/case handling, caller code-page
policy, collation selection and inherited ranges, all eight locale registrations,
all five restored code-page maps, grapheme boundaries and width properties.
The two conformance cases check all **766 grapheme rows** and **20,034 NFD
normalization rows** from Unicode 17. Inputs are ZIP members read into owned
memory; the tests create no expanded fixture files.

The original three collation programs also have an explicit package recipe:

```sh
output/nxbuild-next/x86_64-linux/nxbuild /action=build /project=packages/nexus-packages/rtl-unicode/tests/CollationConformance.nxproject
cp ../nexus-fpc/tests/test/units/fpwidestring/CollationTests.zip output/rtl-unicode/ansi/collation/
output/rtl-unicode/ansi/collation/tuca1
output/rtl-unicode/ansi/collation/tuca2
output/rtl-unicode/ansi/collation/tucawsm
```

Their original archive stays in one FPC test location. Both members are extracted
directly into memory. Each program checks 206,308 non-ignorable and 227,819 shifted
input lines, with zero errors in both compiler modes.

## Initialization and maintenance

Importing UTF8Utils preserves the caller's conversion and filesystem code pages.
`NeedRTLAnsi` follows the current conversion code page unless explicitly overridden
by `SetNeedRTLAnsi`. UTF-8 storage uses explicit byte types in both compiler modes.

Import `unicodeducet` to register DUCET/ROOT; import the required `collation_*`
units for tailored tables. Registration and manager selection are distinct.
Select a registered collation through `fpwidestring.SetActiveCollation` when the
manager is already initialized. An unknown name returns false and preserves the
current selection. No helper changes compiler-wide text defaults.

`src/inc/graphemecontext_code.inc` adds the Unicode 17 Extended_Pictographic and
Indic_Conjunct_Break properties. Regenerate it without network access:

```sh
python3 packages/nexus-packages/rtl-unicode/tools/generate-grapheme-context.py
```

Original headers, little-endian generated data and license texts remain with
the source. Nexus supports little-endian hosts and targets only; the unused
big-endian collation blobs and host selector branches are retired. The
little-endian table blobs are unchanged. The historical `utils/unicode`
collation generator was already retired with the old tool collection and is
not a maintained regeneration path. Future collation imports must retain only
the little-endian layout and unconditional little-endian includes. Retired Make/fpmake workflows and unused namespace aliases have not
been reintroduced. The old normalization runner's useful checks are part of the
direct nxtest suite rather than a second retained runner.
