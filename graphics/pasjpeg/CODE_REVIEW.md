# PasJPEG relocation review

Reviewed on 2026-10-17, before implementation changes. Work authorized by the
owner's request to relocate PasJPEG using the established package workflow.

## Baseline and scope

Source: NexusFPC `packages/pasjpeg`, at repository HEAD
`bfd5d2156b01f1213b3fa16e3b3fde38588c9d5d`. The package was unchanged locally.
The untouched 119-file source snapshot is in ignored Nexus output
`output/pasjpeg-review/untouched`; the exact file inventory and SHA-256 hashes
are saved in `review/baseline-hashes.json` (the inventory is authoritative for
the file count). No duplicate runtime source archive is distributed.

Review focuses on the portable JPEG codec's I/O paths, marker/scan handling,
memory ownership and the BMP/JPEG convenience API. Existing namespace wrappers
and historical platform sources are preserved. Examples remain centralized in
Nexus Lab `examples/graphics/jpeg`; test-only fixtures belong with these tests.
No package test suite was present in the original tree.

## Initial findings to reproduce

1. **Compile failure — convenience API:** `src/pasjpeg.pas` uses missing bitmap
   record types and `ShowMessage`, although its interface only depends on
   Classes/SysUtils. The normal `buildpasjpeg` aggregate does not compile this
   unit, hiding the problem. Compile the unit directly before changing it.
2. **Nil progress callback:** `jpeg_my_progress` intentionally accepts nil, but
   `jpeg_finish_progress` unconditionally dereferences `cinfo^.progress`.
   Exercise both public conversions with a nil callback once compilation is
   repaired; do not count this as proven until those calls fail.
3. **Quantized output allocation — dismissed:** initially suspected because
   the BMP destination is allocated before `jpeg_start_decompress`. Inspection
   confirms `jinit_write_bmp` calls `jpeg_calc_output_dimensions`, which sets
   `output_components` correctly, including indexed output. No fix is needed;
   retain an indexed-output behavioral check.
4. **BMP pixel offsets:** buffered reads start immediately after the palette,
   ignoring `bfOffBits`; seek-based reads count backward from `bfSize` instead
   of the pixel extent. Valid bitmaps with gaps/trailing data can therefore
   encode the wrong pixels. Compare these inputs against the same tightly
   packed bitmap through both public input modes.

The runtime candidates require direct nxtest proofs. Compilation-only repairs
must be applied separately to an ignored copy to expose those baseline
failures without claiming that the untouched source was executable.

## Results

Untouched portable core (`buildpasjpeg`, `jctrans`, `jdtrans`): builds.
Untouched convenience API: fails to compile, first missing type
`TBitmapFileHeader`. A compilation-only repair supplies packed BMP records
without Windows units and sends warnings to standard error instead of the
unavailable GUI routine. The direct `PublicConvenienceAPI` nxtest compiles
against and exercises the restored unit.

The same 13 nxtest cases against the compilation-only copy give **9 pass,
2 failures and 2 errors**. `StoreNilCallback` and `LoadNilCallback` raise
`EAccessViolation`. `BitmapGapBuffered` and `BitmapTrailerSeek` produce
different compressed lengths from identical pixel data without the extra
layout bytes. `BitmapGapSeek` passes, confirming the buffered/seek distinction.
`QuantizedOutput` passes; that initial suspicion is dismissed.
Baseline/proof logs are under ignored Nexus `output/pasjpeg-review`.

Fixes: define the actual BMP header records in `tpPasJPEGBitmap`, use standard
error for diagnostics, stop progress finalization when no monitor is installed,
seek buffered input to `bfOffBits`, and compute the seek-mode pixel extent from
`bfOffBits + row_width * height` rather than `bfSize`.

## Completed relocation and verification

The sole runtime owner is now `nexus-packages/graphics/pasjpeg`; all 119 original
files were moved. The compiler-side directory was deleted after comparing every
original hash and verifying that the other 118 relocated originals were
byte-identical. Only `src/pasjpeg.pas` changed in the inherited runtime.
The packed bitmap definitions are new code in `src/tpPasJPEGBitmap.pas`.

`Package.nxscript` advertises `NXRP.Graphics.PasJPEG` in the pool and repository
catalogs. `PasJPEG.nxpackage` compiles 55 units, including transitive units,
the aggregate, coefficient-transcoding units, constants and the repaired
convenience API. FCL Image now declares its independent PasJPEG requirement.
Native FCL Image/fpGUI recipes, Lab recipes and the language-server search-path
defaults use the new location. An audit of active source/build/config files
found no remaining reference to the deleted compiler source path.

| Verification | Before | After |
| --- | --- | --- |
| Portable core/coefficients build | Pass unchanged | Pass from relocated source |
| Convenience unit build | Missing BMP types; after adding types alone, missing `ShowMessage` | Pass without GUI/Windows units |
| Direct nxtest cases | Compilation-only repair: 9 pass, 2 fail, 2 errors | **13 pass, 0 fail/errors/skips** |
| Core-only nxtest cases on untouched source | **5 pass** | Same behavior retained |
| FCL Image package | Existing consumer | Fresh build succeeds with compiler-side PasJPEG absent |
| FCL Image regression suite | Previously passing | **18 pass, 0 fail/errors/skips** |
| Pool/repository catalogs and both package descriptors | No independent PasJPEG entry | All four validations pass |
| Five canonical native example programs | Old declaration/file-interface errors | All build; six smoke commands pass |
| Independent JPEG interoperability | No retained check | All four Pillow comparisons pass |

Both final test executables explicitly use HeapTrc with failure on unfreed
allocations; final tests and interoperability checks complete without heap
diagnostics. The compiler's automatic `-gh` insertion hit internal error
`2026032615`; explicit HeapTrc import, already used by Nexus image tests, works.
This is test instrumentation only; the codec introduces no dependency on it.

Pillow decodes the new encoder output with mean absolute errors below 0.67 per
color channel on the generated gradient. PasJPEG decoding of independent
baseline, progressive and grayscale inputs matches Pillow **pixel for pixel**
on these fixtures. The canonical CLI checks exercise `cjpeg`, `djpeg`, plain and
progressive `jpegtran`, `demo` and `rdjpgcom`. Both coefficient transcodes retain
the independently decoded pixels. These checks are finite behavior checks,
not claims of exhaustive JPEG conformance.

The old examples' three command-line programs passed Pascal `File` variables
to a codec configured for pointers to `TStream` variables. They now use actual
streams. `cjpeg` retains its existing refusal to overwrite an output file.
`rdswitch` had an invalid `argtxt ansi: string` declaration, now repaired.
Original notices and the existing Lab `rdjpgcom` changes were preserved.

## Preserved material and limits

- Original notices, namespace maps/wrappers and historical sources remain.
  The IJG release 6b README/license was recovered unchanged from IJG's original
  archive; its URL/hashes and the source provenance are recorded in
  [Nexus attributions](../../../../ATTRIBUTIONS.md#pasjpeg). No duplicate runtime
  source archive or generated test output is added to the package.
- The DOS memory managers, Delphi assembly alternative, unused `jmemsys`
  declaration and unfinished `jidct2d` prototype are outside the selected
  portable build. An exploratory compile confirmed the prototype already ends
  mid-unit (`Unexpected end of file`). No production consumer uses it. It is
  preserved original source, not an advertised supported implementation.
- Namespace wrapper validation stops because this installed RTL has no
  `System.Classes`. Wrappers were preserved unchanged; a complete dotted RTL
  SDK was not built for this relocation.
- The fpGUI framework consumer compiles its Pascal sources, then fails to
  link because the host lacks the unversioned `libX11` development library.
  That host prerequisite is not a PasJPEG failure. GUI execution was not run.
- Verification used native Linux x86_64 NexusFPC 3.3.1 and its matching installed
  RTL through Nexus nxbuild. Windows and other targets, historical VCL demos,
  malformed-input fuzzing and a full compiler bootstrap/release matrix were
  not run. Nexus does not require Delphi validation.

Local commands/results and the compilation-only proof copy remain under ignored
Nexus `output/pasjpeg-review`. `review/verification.json` retains the compact
results; `review/baseline-hashes.json` identifies the exact original source.
