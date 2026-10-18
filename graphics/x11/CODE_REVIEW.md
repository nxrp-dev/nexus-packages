# X11 relocation review

Reviewed 2026-10-17 before changing the inherited runtime source. Authorized by
"lets move x11 next", using the standard package relocation workflow.

## Baseline and scope

The source is NexusFPC `packages/x11`, revision
`0f60ce9c1bfd30e56fd6d5246a8ed46077f9990a`. All 125 original files, including
45 runtime units, namespace maps/wrappers and 18 historical programs, are hashed
in `review/baseline-hashes.json`. The immutable Git tree identifies the source
snapshot; an untouched working copy is under ignored `output/x11-review/untouched`.
No second maintained provider or source/evidence archive will be added.

The package supplies Xlib, XKB, X Input, Render, Xft/Fontconfig and extension
bindings. fpGUI uses the core bindings and shared library constants. Compiler
bootstrap has no X11 input. Namespace wrappers and original author/license
notices must move with the source. Demonstrations belong in Nexus Lab; test-only
inputs remain with direct nxtest cases in this package.

## Findings to prove before fixing

1. **Linux library binding/link failures.** Extension units still declare
   unversioned linker names despite the established supported-ABI policy.
   `xrender` imports Render functions from X11 and `xshm` imports shared-memory
   extension functions from X11 instead of their owning libraries. Xft also binds
   `FcFontSetDestroy` to Xft although Fontconfig owns it, leaving a static import
   unresolved. Build and
   exercise the imports using the installed versioned runtime libraries.
2. **Render C ABI mismatches.** Resource IDs declared as `dword` disagree with
   the C `unsigned long` resource types on LP64. Examine affected record layouts,
   attribute fields and mask signatures against the original C API; prove sizes,
   offsets and a real library result before fixing the declarations.
3. **XKB action classification.** `XkbIsGroupAction` uses OR between its lower
   and upper bounds, accepting action types outside the group-action range.
4. **XKB action widths and signed values.** Several action setters accept only
   Byte although their fields hold 16/32-bit values; pointer motion getters
   return unsigned words. Signed byte/word conversion must also work with range
   checks. Prove each affected family with independent fixed values.
5. **Redirect virtual modifier writes.** The setter writes mask fields and
   forces its low byte to `$FF`; verify that value and mask updates are distinct.
6. **Keyboard symbol indexing/counts.** `XkbCMKeyNumSyms` uses OR instead of
   multiplication; `XkbCMKeySymsOffset` returns Byte for a 16-bit offset. Exercise
   maps with multiple groups and offsets beyond 255.
7. **Keyboard action entry result.** `XkbKeyActionEntry` returns an index Byte
   instead of an action pointer. Verify the selected entry and the no-action
   result, without changing unrelated action semantics.
8. **DevicePresence output is discarded.** Its event-class argument is passed
   by value. Query the extension on an available display and check the returned
   event type and class together.

9. **Geometry helpers expose wrong widths/types.** Bounding-box differences
   can exceed SmallInt; several shape helpers return a doodad pointer although
   their actual target is a geometry shape. Prove the extent and pointed-to type.
10. **Fontconfig value layout is incomplete.** `TFcType` is Byte rather than a
    C enum and `TFcValue` omits its value union. Compare the public ABI layout.

Additional review checks include public structure widths, imported symbol
ownership, enum representation, XI event masks and original link-test intent.
Suspicions that cannot be reproduced are not implementation fixes. Historical
link-only programs pass nil Display pointers deliberately and must not be run
as behavioral tests. The keyboard-map printer is a demonstration, not a test.

## Proof and final results

### Baseline proof

The untouched XKB build fails because `libX11` is no longer visible through
Xlib's interface: XKB must import the actual library-name owner. An independent
untouched import probe selecting X Input, Render and shared-memory functions
also fails at native linking with `unable to find library -lXi`. The same probe
builds after the library corrections, using actual installed versioned runtime
libraries and no fabricated development symlinks. A separate static Fontconfig
import probe against the library-only baseline also reproduces
`undefined symbol: FcFontSetDestroy`; the direct `RuntimeLibraries` case now
references that static binding and destroys an actual empty font set created
through Fontconfig's dynamically loaded constructor. An initial function-address identity assertion was discarded: it failed
even for the correctly linked binding and did not establish whether a client
could link and use the API. The test now exercises allocation/destruction.

To expose the behavioral defects behind those compile/link failures, a temporary
copy received **only** the library constant/import corrections. No helper, C
layout, action signature or DevicePresence argument was changed in that copy.
Against it, the direct core suite produces **3 passed, 5 failures, 9 errors**;
the binding suite produces **20 passed, 5 failures, zero errors**. The complete
42-case baseline therefore has **23 passes and 19 reproduced failures/errors**.
This is a compilation-only repaired baseline, not a claim that untouched XKB
could execute. Exact logs and working projects are under ignored
`output/x11-review`.

| Finding | Direct proof | Correction |
| --- | --- | --- |
| Library import/build closure | Untouched XKB cannot resolve `libX11`; untouched extension probe cannot find `-lXi`; `RuntimeLibraries` and imported runtime calls pass afterward | Import `tpX11Libraries` directly, centralize supported sonames, remove unversioned link directives/local duplicates, import Render from Xrender, shared memory from Xext and font-set destruction from Fontconfig |
| Render/Xft ABI | `RenderABI`, `XftABI` and `RenderRuntime` fail; a real visual format reports the wrong depth through the old record | Use C unsigned-long resource IDs and masks, append the missing `component_alpha` member, correct Xft's Picture and Colormap widths |
| Group action range | `GroupAction` classifies type 0 as a group action | Require both range bounds |
| Action widths/signs | `SignedWords`, `ModAction`, `PointerWrite`, `PointerRead`, `SignedActions`, `Controls` raise checked-build range errors | Use full 16/32-bit fields, signed pointer coordinates and signed action fields directly; decode signed words without overflowing an intermediate SmallInt |
| Redirect modifiers | `RedirectValue` writes no value and corrupts the mask; `RedirectWidths` raises a range error | Write value fields separately from masks and accept all 16 modifier bits |
| Symbol maps | `SymbolCount` reports 3 instead of 6; `SymbolOffset` fails at offset 512 | Multiply width by groups and retain the full Word offset |
| Action entry | `ActionEntry` returns a small ordinal instead of the selected action address | Return the actual action pointer; return typed nil for no action |
| Presence output | `DevicePresence` leaves the event-class sentinel unchanged while returning a valid event type | Make both results explicit output arguments |
| Geometry | `GeometryBounds` fails at extent 64000; `GeometryShape` exposes a 24-byte doodad where the actual shape is 48 bytes | Use C-width integer extents and the real shape-pointer type for shape getters/setters |
| Fontconfig layout | `FontconfigABI` exposes a one-byte enum and missing value storage; native C reports enum 4 and value 16 | Use `cint` for the enum and restore the aligned typed value union |

`SignedBytes`, XI mask operations and the keyboard map-entry C Bool layout pass
before and after. The stale keyboard demonstration's comment about a Boolean
layout defect does not describe the current source: that field already uses
`TBool`. No unrelated Bool repair was applied.

### Completed ownership and integration

The sole maintained source is now `nexus-packages/graphics/x11`. All 125 original
files were copied and hash-checked **before** the compiler-side directory was
removed and implementation corrections began. Of that inventory, **77 files**
remain byte-identical, including every namespace wrapper/map; **30 runtime
files** change for the proven corrections. The other 18 files were programs:
17 link-only programs became direct nxtest symbol checks and the keyboard-map
printer became the Lab demonstration. No redundant old runners are maintained.
All 45 runtime units and 16 include files remain in the package.

`Package.nxscript`, `X11.nxpackage`, the test recipe, both catalogs and fpGUI's
source-package requirement describe the new owner. Fifteen consumer recipes
and the private helper's X11 path use it. Editor defaults and the bundled editor
configuration now discover the relocated source. The Lab keyboard-map program
has its own Nexus build recipe and is registered in the Lab Forge catalog.
Original notices, namespace maps, FPC/fpGUI license texts and the fpGUI author
record accompany the source; provenance is in
[Nexus ATTRIBUTIONS.md](../../../../ATTRIBUTIONS.md#x11).

### Final native Linux x86-64 verification

- **45/45 package units build** with the configured native NexusFPC and nxbuild.
  The inherited C translations use the package's normal FPC mode; explicit
  per-unit modes remain. Selecting ObjFPC globally incorrectly treats the old
  C parameter name `class` in MultiBuffer as a language keyword; correcting
  that verification/build setting needs no binding implementation change.
- **42/42 direct nxtest cases pass**, with range and overflow checks enabled:
  17 core and 25 binding cases, zero failures/errors/skips. The binding run uses
  a private Xvfb display, exercises real Render/shared-memory/input/keyboard
  calls and resolves **227 original extension symbols** in 17 groups.
- The independent native C probe confirms Render IDs are 8 bytes, its format
  record 40 bytes and attributes 72 bytes; Fontconfig's enum/value are 4/16.
  Nine selected core XKB record sizes match the independently compiled C
  headers, including client/server maps, descriptors, geometry and device info.
- A fresh fpGUI framework build passes **566 tests**, zero failures/errors/skips.
  On 2026-10-18 the owner requested removal of the test tied to an external
  Haiku `Alert_Idea.hvif` fixture. Its declaration, implementation, runner and
  registration were removed; rebuilding and rerunning the suite confirms the
  result above (`output/x11-review/skip-removal-fpGUIFrameworkTests-results.log`).
- Fresh Setup and Virtual TreeView application builds succeed. The centralized
  keyboard-map demonstration builds and executes against Xvfb, including key
  code 255. The corrected import probe and editor-defaults unit build succeed.
- The X11 descriptor, both catalogs and the updated GUI descriptor validate
  through the native NexusScript CLI. The final source audit finds zero active
  references to the old compiler package, verifies all 15 consumer paths and
  unchanged namespace wrappers, and loads all 12 configured Linux runtime ABIs.
  Compiler/RTL/bootstrap changes are not part of this relocation.
- Diff whitespace checks pass, including the new source against its baseline.
  The standard checkpoint helper now includes `.nxproject` and `.c` files so
  the build/test recipes, optional C reference and accompanying license/provenance
  records are preserved in the normal source checkpoint. No tracked evidence
  archive is added.

### Limits

Verification is native Linux x86-64 with the standard build defines and an
isolated Xvfb server. Other platform branches and a complete dotted RTL SDK
were not built. Namespace wrappers and their includes are preserved unchanged.
The Xvfb checks cover the stated calls, not every optional extension behavior,
real hardware input, shared-memory image transfers or every display server.
This is a complete unit/source-package build; no compiled `.nxpl` publication
is claimed. Test servers are stopped after each run. Development headers and
Xvfb were extracted only into ignored verification output, never installed as
package source or a compiler-bootstrap dependency.
