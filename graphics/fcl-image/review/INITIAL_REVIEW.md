# FCL Image code review

Review date: 2026-10-16. Source: NexusFPC revision
`ca6b3976bf5417fd73251dcb9f39d9edcf48ea07`, `packages/fcl-image`.

The review covers image storage/palettes, canvas and drawing helpers, codecs,
barcode/QR, FreeType adapters, wrappers, examples and integration. Findings are
concrete source defects; regression outcomes are recorded after verification.
No implementation was changed before this review was saved.

All 148 original files are preserved in `review/baseline-source.tar.gz` and
`review/baseline-hashes.json`. The working original is also retained under
Nexus `output/fcl-image-tests/baseline-package`. Original headers, assets,
examples and the barcode suite remain with the relocated package.

## Initial findings

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
| 11 | P1 | fpwritebmp/pcx/pnm/qoi/tga/tiff.pas | Unchecked output writes report success after partial output. Inject short writes at headers and payloads and require a write error. |
| 12 | P2 | fpwritepcx.pas:83,139-160 | Odd-width PCX uses an odd plane stride instead of even-byte padding. Check the header and independent RGB plane bytes, compressed and raw. |
| 13 | P1 | fpreadtga.pas:117,285 | Header combinations are not validated together and indexed pixels lack an upper palette bound. Reject invalid depth/map combinations and out-of-range indices before memory access. |

## Baseline

All 56 runtime units compile with NexusFPC 3.3.1 on x86_64 Linux after including
the transitive hash/CRC dependency needed by paszlib. The retained barcode runner
passes all 17 tests. No retained test was removed. Review regressions and final
package/consumer verification are pending.

Format references: [QOI specification](https://qoiformat.org/qoi-specification.pdf),
[Netpbm PGM](https://netpbm.sourceforge.net/doc/pgm.html),
[Netpbm PPM](https://netpbm.sourceforge.net/doc/ppm.html),
[ZSoft technical reference, revision 5](https://techheap.packetizer.com/compression/graphics/pcxfmt.html),
[Truevision specification archive](https://github.com/DEAKSoftware/Truevision-TGA).

Provenance and license details belong to the
[canonical attribution record](../../../../ATTRIBUTIONS.md#fcl-image).
