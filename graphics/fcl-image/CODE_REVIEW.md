# FCL Image code review

Reviewed and relocated on 2026-10-16 from NexusFPC
`ca6b3976bf5417fd73251dcb9f39d9edcf48ea07`, `packages/fcl-image`.

The initial source review was saved before implementation changes. It is retained
as `review/INITIAL_REVIEW.md`; findings added during integration are included
below. All 148 original files are preserved in `review/baseline-source.tar.gz`
and identified by `review/baseline-hashes.json`. Original notices, headers,
examples, assets, namespace wrappers and useful tests remain with the package.

## Results

**Untouched source: 0 passed, 18 failed. Corrected source: 18 passed, no
failures, errors or skips**, using NexusFPC 3.3.1 on x86_64 Linux. There is one
nxtest case per finding. Each case runs in a bounded fixture process, with range
checks and heap guards. The corrected suite also passes without range/local
instrumentation; heap guards remain enabled. The baseline's two buffer overruns
are detected as corrupted heap tails, not merely inferred from output pixels.

The retained FPCUnit barcode runner passes **17/17 before and after**. No retained
test was removed. All **56 runtime units** and **13 original example programs**
compile. The runtime, example, regression and retained-suite recipes build through
nxbuild. The package descriptor and both catalogs validate through NexusScript;
nxbuild evaluates build recipes with the native target selected. The generic
NexusScript CLI does not select a build target and reports duplicate Native
members when given the shared multi-target build environment; that attempted
validation is retained as tooling evidence, not a package failure.

The language-server search-path consumer compiles and resolves the relocated
directory. The fpGUI PNG and JPEG adapters compile against the relocated source.
Six retained example programs were exercised: drawing, barcode generation,
QR generation, image conversion, QOI writing and font rendering. Eleven exact
pixel comparisons through Pillow independently check BMP, TGA, PNM, TIFF, PNG
and QOI output and round trips. The font example initially exposed finding 18;
after its fix, default loading renders the retained DejaVu asset successfully.

The applied removal patch deleted only the 148 original package files and
updated the NexusFPC relocation checklist. Its paths have no overlap with the
pre-existing resource changes. Some resource files continued changing during
this task; the final verification records that concurrent activity without
claiming their hashes stayed constant. The root attribution record is canonical.

## Findings and verified corrections

Locations refer to the untouched snapshot. All findings below have reproduced
failures and corresponding passing nxtest cases in `tests/tsFCLImageTests.pas`.

| ID | Priority | Original source | Failure / regression |
|---|---|---|---|
| 01 | P2 | fpreadqoi.pas:134 | Initial QOI index table is seeded with opaque black instead of entirely zero. Decode an initial index 53 as transparent black. |
| 02 | P2 | fpreadqoi.pas:205; fpwriteqoi.pas:235 | Byte arithmetic raises range errors for valid modulo-256 QOI differences. Exercise DIFF/LUMA wrap and encoder negative deltas with range checks. |
| 03 | P1 | fpreadqoi.pas:106-283 | Unbounded chunk pointer reads and early loop exits accept truncated chunks, missing markers, incomplete images and oversized runs. Reject malformed data and invalid headers; accept valid opcode vectors. |
| 04 | P2 | fpreadpnm.pas:296 | ASCII words are byte-swapped at maxval 65535, but raw words at other maxima are not. Check ASCII/raw grayscale and RGB against independent expected sample values; reject maxval above 65535. |
| 05 | P1 | fpwritepnm.pas:289 | Automatic depth detection skips saturated colors and saves a pure red image as monochrome. Preserve RGB and nonbinary gray values. |
| 06 | P1 | fpwritepnm.pas:220-240 | ASCII sample padding writes five bytes into a four-byte slot, overrunning the final scanline allocation. Exercise ASCII PGM and PPM under heap guards. |
| 07 | P2 | fpreadpcx.pas:77,98,135 | Palette samples do not span the 16-bit channel range. Check 16/256-color and gray palette endpoints. |
| 08 | P1 | fpreadpcx.pas:145-196 | Unsupported plane/depth combinations and undersized rows reach unchecked pixel reads; invalid RLE runs are accepted. Reject malformed headers/runs and release scanline memory on failure. |
| 09 | P2 | fpreadtga.pas:147-188,299-350 | TGA palette, grayscale, 16-bit channels and 8-bit alpha lose intensity/alpha precision; 16-bit palettes are read as three bytes. Check independent palette/truecolor/gray vectors. |
| 10 | P1 | fpreadtga.pas:99-108,197 | Reused readers overwrite live allocations and keep RLE state; FreeBuffers clears the wrong pointer after freeing the palette. Check repeated compressed images and buffer cleanup. |
| 11 | P1 | fpwritebmp/pcx/pnm/qoi/tga.pas | Unchecked output writes report success after partial output. Inject short writes at headers and payloads and require a write error. |
| 12 | P2 | fpwritepcx.pas:83,139-160 | Odd-width PCX uses an odd plane stride instead of even-byte padding. Check the header and independent RGB plane bytes, compressed and raw. |
| 13 | P1 | fpreadtga.pas:117,285 | Header combinations are not validated together and indexed pixels lack an upper palette bound. Reject invalid depth/map combinations and out-of-range indices before memory access. |
| 14 | P2 | fpreadpnm.pas:83 | Reusing an ASCII PNM reader after trailing whitespace probes stale buffered bytes instead of the new stream. Decode two independent images with one reader. |
| 15 | P2 | fpreadtga.pas:285-357 | The horizontal-origin descriptor flag is ignored, mirroring right-origin TGA images. Check a two-pixel right-origin image against explicit colors. |
| 16 | P1 | fpwritebmp.pas:433-444 | RLE4 temporary storage is only Width bytes, but the nibble expansion writes the padded even width. Exercise odd-width compressed BMP under heap guards. |
| 17 | P2 | fpreadbmp.pas:375-445 | RLE4 packs uninitialized scratch padding into bytes. A valid narrow image can raise a range error. Decode a valid even-width RLE4 image with range and heap checks. |
| 18 | P2 | libfreetype.inc:42 | Linux dynamic loading defaults to the unversioned build-time library name, so default font initialization fails with the installed runtime SONAME `libfreetype.so.6`. Verify runtime availability independently, then initialize the font engine through its default loader. |

Corrections keep color expansion/scaling explicit, validate codec headers and
row/index boundaries before access, preserve reader state across independent
loads, check output completion, and release owned buffers on error. QOI decoding
now reads bounded chunks directly from the stream and verifies the final marker;
it no longer allocates a copy of the entire remaining input. QOI arithmetic uses
explicit modulo-256 operations. PCX pads each plane independently. TGA handles
16-bit color and 8-bit alpha numerically and honors horizontal origin. BMP RLE4
allocates its padded scratch width and initializes reader padding. The initial
relocation changed Linux's dynamic FreeType default to `libfreetype.so.6`.
The subsequent 2026-10-17 Linux shared-library correction applies that same ABI
name to linked FreeType bindings too; see the
[follow-up verification](../../../../docs/reviews/linux-shared-libraries.md).

The initial unchecked-write candidate included TIFF. Runtime injection disproved
that part: TIFF stages into memory and its final CopyFrom already rejects short
output. Its implementation was restored byte for byte; the regression retains
TIFF as a passing control. The corrected short-write finding applies to BMP,
PCX, PNM, QOI and TGA. The PCX writer's ineffective compression run search still
produces valid encoded data; it was not treated as a correctness failure or
changed opportunistically.

## Evidence and reproduction

`review/evidence/` preserves baseline outcomes, the two heap corruption reports,
corrected and uninstrumented results, retained-suite counts, consumer/example
results and final relocation verification. Larger compiler logs and generated
images remain under Nexus `output/fcl-image-tests`.

Use the nxbuild commands in [README.md](README.md) for normal builds. The
[comparison harness](tests/VerifyReview.py) verifies/extracts the immutable archive
when needed and compiles the same new tests against either source tree. The
baseline is never patched. Baseline failure is the expected result.

## Scope and limits

Inspection covered the package's storage/palette and canvas interfaces, drawing
helpers, codecs, barcode/QR and font integration. Runtime proof concentrates on
the concrete codec and lifecycle findings; this is not exhaustive fuzzing of
every input format or a complete visual rendering comparison. Windows execution,
all format variants, namespaced builds and full compiler bootstrap/cross builds
were not verified. These are recorded limits, not a claim that the relocation
rebuilt the toolchain. Delphi is not supported and is not required.

The requested spoken completion notification could not run because `pwsh` is
not installed on this host.

Format references: [QOI specification](https://qoiformat.org/qoi-specification.pdf),
[Netpbm PGM](https://netpbm.sourceforge.net/doc/pgm.html),
[Netpbm PPM](https://netpbm.sourceforge.net/doc/ppm.html),
[ZSoft technical reference, revision 5](https://techheap.packetizer.com/compression/graphics/pcxfmt.html),
[Truevision specification archive](https://github.com/DEAKSoftware/Truevision-TGA).

Authorship, revisions, font metadata, license expressions and import evidence:
[canonical Nexus attributions](../../../../ATTRIBUTIONS.md#fcl-image).

## 2026-10-16 native retained-test conversion

Useful retained behavior tests now use nxtest directly. The former FPCUnit
helpers and runners were removed, with their originals preserved in hashed
archives. The [retirement report](../../../../docs/migrations/fpcunit/README.md) records conversions,
corrected invalid expectations, before/after results and verification limits.
