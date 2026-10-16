# FCL XML code review

Review date: 2026-10-16. Reviewed NexusFPC revision:
`ab22ed40f859707684f48e2a91359fe61e3ebeb9`.

Scope: the 22 runtime units, namespace wrappers, package integration and retained
reader/DOM/XPath tests. Findings below are tied to the reviewed snapshot.
An immutable copy of all 71 package files and SHA-256 hashes is saved under
Nexus `output/fcl-xml-tests/baseline` and `baseline-hashes.json`.

## Verification and corrections

**Original source:** 0 passed, 14 failed, 0 skipped.
**Corrected source:** 14 passed, 0 failures/errors/skips on x86_64 Linux,
NexusFPC 3.3.1. [tsFCLXMLTests.pas](tests/tsFCLXMLTests.pas) registers one
bounded fixture case per finding. Each regression was run against the preserved
original source and the corrected source. The corrected suite also passes
without instrumentation.

| Cases | Verified correction |
| --- | --- |
| 01–04 | Clear marks changes and invalidates cached keys in XMLConf; XMLCfg also marks clears. Document replacement validates and parses before adopting ownership, resets cached key nodes, preserves prior state on failure and retains filename-based URI resolution. Root renames preserve attributes and children in both configuration units. |
| 05–07 | Floating remainder replaces integer narrowing, with explicit special-value handling. Rounding keeps floating values, infinities and signed zero. Numeric truth/equality use exact zero/equality tests. |
| 08 | Empty prefixes remove the prefix and colon. Attached attributes are reinserted in the sorted qualified-name map when their prefix changes. |
| 09 | XML and HTML writers use WriteBuffer and free their output buffer even when flushing raises. Both short flushes and full-buffer writes are exercised. |
| 10 | iconv status remains size_t; decoded characters are counted before updating residual capacity. Both normal and partial conversions count toward MaxChars. Range-check and uninstrumented baseline failures are retained, and a valid multibuffer non-ASCII decode succeeds. |
| 11–12 | Existing unsupported streaming writes and the XPath namespace axis raise explicit errors. Missing writer overrides no longer dispatch to abstract methods, and failed object writes release their open stack frames. |
| 13–14 | Nonvalidating parsing records declared ID identity. Unprefixed XPath names require an empty namespace. |

The retained reader/DOM suites pass all 36 tests before and after. The original
XPath runner printed four failures despite returning success. Three were real
implementation bugs: ID identity, unprefixed namespace matching and the
namespace-axis result shared by two expressions. Namespace-axis evaluation
remains unsupported and is now rejected explicitly. Its two success expectations
were replaced by nxtest rejection coverage; the ID and namespace-name assertions
remain unchanged and pass. The runner now returns a nonzero exit code on failure;
a temporary copy with one deliberately wrong expectation was verified to return
exit 1 and report exactly one failure.

The package recipe compiles all 21 Linux-applicable runtime units. The target
encoding selection preserves the Windows adapter without compiling it on Linux.
The nxpackage descriptor, both catalogs and the test project are registered.
The JSON consumer suites also pass against the relocated XML source: JSON 415
(one existing ignore), generator 77, configuration 9 and INI 28, with zero
failures/errors. The language-server search-path unit compiled and resolved the
new directory; the Forge fixture and both package catalogs validated.
The root AGENTS.md now requires the same review, provenance, package integration,
regression proof and correction workflow for future relocations.

The standalone reader/DOM and XPath tests are local retained suites; the
external W3C compliance corpora referenced by the older harnesses were not
present and were not executed. Windows execution has not been verified. Delphi
is not a supported Nexus target and is not a completion requirement.

Evidence: `output/fcl-xml-tests/baseline-hashes.json`,
`baseline/regression-results.txt`, `baseline/iconv-plain-results.txt`, fixed
regression/retained-suite logs and the final relocation verification. A copy of
the initial static review was saved before relocation and implementation.

## Original findings (all reproduced)

| ID | Priority | Source | Failure and required regression |
| --- | --- | --- | --- |
| 01 | P1 | xmlconf.pas:135; xmlcfg.pas:125 | Clear replaces the root without marking the configuration dirty; XMLConf also keeps its cached key on the detached root. Flush can preserve deleted values or lose later edits. Check clear, current keys and reopened files. |
| 02 | P1 | xmlconf.pas:168-192,407 | Replacing the document does not invalidate the cached current-key element. Subsequent relative access uses storage from the old document. Check both stream and filename changes with an open key. |
| 03 | P1 | xmlconf.pas:168-192 | File loading bypasses root validation; both loaders free the active document before parsing succeeds. Check malformed/wrong-root loads preserve usable prior state and dirty state. |
| 04 | P1 | xmlconf.pas:434; xmlcfg.pas:417 | RootName migration moves child elements but discards root attributes, which hold root-level configuration values. Check root and nested values survive a rename and reopen. |
| 05 | P2 | xpath.pas:810 | mod narrows both operands to integers, changing fractional remainders and causing integer division by zero for fractional or zero divisors. Check positive/negative fractions and exceptional values. |
| 06 | P2 | xpath.pas:2795-2832 | floor/ceiling/round narrow through integer-returning helpers, mishandling infinity, large finite values and signed zero. Check those boundaries and half ties. |
| 07 | P2 | xpath.pas:836-854,1476 | IsZero/SameValue apply tolerances to XPath numeric Boolean/equality operations. Check a tiny nonzero number and distinct nearby values. |
| 08 | P2 | dom.pas:2799 | SetPrefix rejects an empty prefix and always prepends a colon; renaming an attached attribute also leaves the qualified-name map out of order. Check prefix removal, assignment and attribute lookups. |
| 09 | P1 | xmlwrite.pas:332,349; htmwrite.pas:137,149 | Buffered writers ignore short TStream.Write results and silently report successful output. Check short writes during flush and full-buffer writes produce EWriteError. |
| 10 | P1 | xmliconv.pas:41 | Decoder returns iconv's conversion-status count instead of decoded character count, bypassing MaxChars accounting; its partial-output path overwrites the count before calculating it. Check an iconv encoding against the same character budget as UTF-8. |
| 11 | P1 | xmlstreaming.pas:136-221,229,244 | Unsupported collection/list, binary and scalar writes print diagnostics and discard data. Missing overrides still allow abstract-method failures. Check unsupported writes raise explicit serialization errors and stack cleanup remains bounded. |
| 12 | P2 | xpath.pas:1233 | The unimplemented namespace axis silently yields an empty node set. Reject it explicitly instead of returning a false successful result; do not invent a namespace-node ownership model during relocation. |
| 13 | P2 | xmltextreader.pas:3525,3767 | DTD-declared IDs are registered only during validation, so nonvalidating DOM parsing loses known ID identity. Check GetElementById and XPath id() in both validation modes. |
| 14 | P2 | xpath.pas:1113 | An unprefixed name test ignores the node namespace, selecting elements in a default namespace. Check a namespace-aware DOM where `item` must not match a namespaced child. |

The namespace axis and incomplete object-streaming operations are existing
unsupported features. Their correction is explicit rejection, not a claim to
implement those formats/features.

Baseline: all 21 Linux-applicable units compile. The Windows encoding unit is
platform-specific. The retained reader/DOM runner passes 36 tests. xpathts prints
four failures while returning zero; their final disposition is recorded above.

Normative references: [XPath 1.0](https://www.w3.org/TR/1999/REC-xpath-19991116/)
and [DOM Level 2 Core](https://www.w3.org/TR/DOM-Level-2-Core/).
