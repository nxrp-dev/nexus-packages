# RTL Unicode restoration review

Status: restored and verified on native Linux, 2026-10-17.

## Baseline and scope

The reviewed source is NexusFPC `ab6ea7e3d03556520972fbd480b37c6611e1b7fa`,
immediately before `334e806fea1b1ee4cd89d6ccf4ac8a74e19cb83c` removed
`packages/rtl-unicode`. That immutable Git tree is the untouched source snapshot;
`UPSTREAM.sha256` records its original paths and bytes. There is one maintained
source tree, here. Retired Make/fpmake build files are not restored as workflows.

The owner authorized restoration to the main package repository after reviewing
these findings. ANSI remains the compiler default. The same source must support
Unicode defaults and explicit UnicodeString/WideString use under ANSI defaults.
Each compiled artifact must use its matching RTL mode. Compiler bootstrap and its
build sequence remain unchanged.

## Findings recorded before implementation

1. **UTF-8 buffers depend on the default Char width (P1).** UTF8Utils uses Char
   for byte buffers and multiplies byte copy lengths by SizeOf(Char), including
   UTF8StringReplace. Unicode-default builds therefore copy twice the required
   bytes. Regressions must check replacement with equal/different lengths and
   code-point encoding byte for byte in both modes, then fix explicit byte types
   and counts.
2. **Inherited collation upper limit overwrites the lower limit (P2).** Current
   RTL unicodedata.PrepareCollation assigns base.VariableHighLimit to
   p.VariableLowLimit. Restored locale units call this routine. A regression must
   inherit distinct limits, prove the wrong result, and verify both corrected
   bounds and locale behavior. The actual definition stays in the RTL.
3. **Grapheme enumeration relies on unused emoji properties (P2).** The
   enumerator still tests E_Base/Glue_After_Zwj/E_Base_GAZ, but its own generated
   property table returns none of these values. It lacks the Unicode 17 GB11
   Extended_Pictographic rule. Prove joined-emoji failures before correcting the
   segmentation rules and verifying version-matched conformance data.

## Integration decisions

- A collation's registration and its activation are separate. Preserve explicit
  selection through fpwidestring.SetActiveCollation and test initialization after
  the manager is already loaded. Do not install tables into compiler bootstrap.
- UTF8Utils currently changes global conversion/filesystem code pages during
  initialization in ANSI builds. Importing utility functions should preserve the
  caller's policy. Record and test the original side effect before removing it.
- Restore the code-page maps and width helpers, preserve original notices, and
  keep the existing compressed collation fixtures. Use direct nxtest tests with
  no FPCUnit bridge. Ordinary package integration uses Nexus build tools.

## Reproduction and corrections

The immutable package source was recovered independently into an ignored test
directory, checked against Git, and compiled with the same test source as the
candidate. Both baseline RTLs came from NexusFPC
`187e411902eab39c79b6265c6272cd20a3372c34`. Fixed RTLs differ by the single
PrepareCollation assignment described above. Full RTL compilation used the
existing Forge RTL steps in an isolated source snapshot; the live compiler,
installed RTL and bootstrap sequence were not changed. The installed native
NexusFPC compiler SHA-256 was
`3fa47969de3a001467f3954a78b18d68f6daead0c88155549a613e0a209bcba0`.

| Regression | Untouched result | Correction and final result |
| --- | --- | --- |
| UTF8Encode, ReplaceEqual, UTF8RoundTrip, UTF8Case | Failed byte comparisons under Unicode defaults | Explicit AnsiChar buffers/casts and byte copy lengths; all pass in both modes |
| InheritedLimits, Locales | Wrong inherited lower bound and shifted punctuation comparison in both modes | Assign the inherited upper bound to VariableHighLimit in its existing RTL owner; both pass |
| EmojiZWJ | Joined woman/ZWJ/laptop sequence splits | Unicode 17 GB11 with Extended_Pictographic; passes |
| IndicConjunct | U+0915 U+094D U+0915 splits | Unicode 17 GB9c with Indic_Conjunct_Break; passes |
| GraphemeConformance | First mismatch at data row 741 in both modes | Both segmentation corrections; all 766 rows pass |
| ImportPolicy | Import overrides the caller's code pages in ANSI mode | Remove UTF8Utils.InitUTF8 policy changes; both modes preserve the caller's settings |
| SystemConversions | Locale-based NeedRTLAnsi disagrees with explicitly selected CP1252 in both modes | Follow the current conversion code page, preserving the explicit override API; CP1252/UTF-8 transitions pass |

The growing/shrinking replacement vectors passed on the baseline; they were not
counted as separate proven failures. Their byte counts were corrected as part of
the same width defect. The unchanged normalization implementation passed before
and after; it was not rewritten.

An initial activation assertion assumed the manager would still be empty after
all unit initialization. Code-page changes can legitimately initialize it again,
so that assertion was invalid and was corrected. The retained test verifies
explicit locale selection, failure for an unknown name without losing the
selection, and canonical-equivalent comparison after selecting DUCET. No new
manager abstraction or automatic activation mechanism was introduced.

## Final verification

| Check | Result |
| --- | --- |
| Untouched-source direct nxtest cases, ANSI | 12 passed, 7 failed |
| Untouched-source direct nxtest cases, Unicode | 9 passed, 10 failed |
| Corrected direct nxtest cases, ANSI | 19 passed, 0 failed/errors/skipped |
| Corrected direct nxtest cases, Unicode | 19 passed, 0 failed/errors/skipped |
| Package unit builds, matched ANSI and Unicode RTLs | Both pass; all runtime units and the two build aggregates compile |
| Unicode 17 grapheme fixture | All 766 rows pass in each mode |
| Unicode 17 normalization fixture | All 20,034 rows and five NFD relations per row pass in each mode |
| Original tuca1, tuca2, tucawsm programs | All six runs pass; each checks 206,308 non-ignorable and 227,819 shifted input lines, zero errors |
| Existing CollationDataTests | All 5 extraction/ownership/corruption cases pass |
| Clean working/temporary directories | Both corrected runners leave zero files |
| Descriptor and both package catalogs | Validate; both catalog entries resolve the same NXRP.RTLUnicode descriptor |
| Grapheme property regeneration | Byte-identical from pinned ZIP members, without network access |
| Source packaging | Preserves the nxpackage recipe, source hash manifest and nested fixture ZIP bytes |

Local logs, recipes and compact before/after JSON records are under Nexus
`output/rtl-unicode`; this ignored build output is not a retained evidence archive
or a second maintained source tree. The source hash manifest and this report are
the durable review evidence.

## Limits

Verification is native Linux x86-64 in both text modes. Big-endian data and other
platform builds were preserved but not executed. Locale coverage includes all
eight registrations, basic ordering and shifted punctuation; it is not a full
external CLDR tailoring conformance suite. The build recipe is the standard
Nexus source-package/unit build; no compiled runtime-package publication is
claimed. Restoring these services does not establish parity for every unrelated
package under Unicode defaults.

Provenance and licensing belong in the root
[attribution record](../../../ATTRIBUTIONS.md#rtl-unicode).
