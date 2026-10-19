# FCL Image

Image storage, canvases and drawing helpers; image readers/writers; barcode and
QR generation; FreeType adapters. Relocated from NexusFPC `packages/fcl-image`
on 2026-10-16. The [saved review](CODE_REVIEW.md) records 18 reproduced findings,
regressions and fixes. All 148 original files are preserved in the review archive
and hash inventory. The existing examples, font asset, notices, wrappers and
17 barcode tests remain intact.

Provenance, authors and mixed upstream licensing are recorded in the
[canonical Nexus attributions](../../../../ATTRIBUTIONS.md#fcl-image).
The font's original embedded license is also retained as text beside the asset.

`Package.nxscript` registers `NXRP.Graphics.FCLImage` in both catalogs.
`FCLImage.nxproject` builds all 56 ordinary runtime units. Namespace wrappers
remain available for separate consumers. The recipe uses NexusFPC RTL,
RTL-ObjPas, relocated FCL Base, the adjacent PasJPEG package, authoritative
self-contained NexusFPC PasZLib; its CRC32 is private to compression.
Font rendering needs the platform FreeType runtime; Linux's linked and dynamic
bindings use its ABI name `libfreetype.so.6`. A runtime-package SDK is not required.

From the Nexus root, with nxbuild available:

```sh
nxbuild /project=packages/nexus-packages/graphics/fcl-image/FCLImage.nxproject /action=build
nxbuild /project=../nexus-lab/examples/graphics/images/FCLImageExamples.nxproject /action=build
nxbuild /project=packages/nexus-packages/graphics/fcl-image/tests/FCLImageTests.nxproject /action=build
output/fcl-image-tests/x86_64-linux/FCLImageTests
nxbuild /action=build /project=packages/nexus-packages/graphics/fcl-image/tests/FCLImageBehaviorTests.nxproject
```

Native host/compiler settings are in
[`nxbuild.environment.nxscript`](../../../../projects/nxbuild/nxbuild.environment.nxscript).
Runtime units go to `output/nxbuild-fcl-image/<target>`; examples go to
`output/fcl-image-tests/examples/<target>`. Source consumers use `src`.
The language server's default source path uses this relocated directory.

See [tests/README.md](tests/README.md) for the original-source comparison.
