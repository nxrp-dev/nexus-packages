# PasJPEG

Portable Pascal JPEG compression/decompression, progressive scans, coefficient
transcoding, scaling and color quantization. The `PasJPEG` unit additionally
converts between BMP and JPEG streams. Relocated from NexusFPC
`packages/pasjpeg` on 2026-10-17; the runtime now has one source owner here.

[Review and verification](CODE_REVIEW.md) records the original hashes,
compilation proof, runtime regressions and corrections. Authors, source revision
and mixed licensing are recorded in
[Nexus attributions](../../../../ATTRIBUTIONS.md#pasjpeg).
`readme.txt` retains the Pascal translation's original notice; `README.IJG`
retains the original IJG release 6b README/license; `COPYING.FPC` preserves the
compiler distribution notice. The new bitmap definitions and tests carry their
own MPL notices. This software is based in part on the work of the Independent
JPEG Group.

`Package.nxscript` registers `NXRP.Graphics.PasJPEG`. From the Nexus root:

```sh
nxbuild /action=build /project=packages/nexus-packages/graphics/pasjpeg/PasJPEG.nxpackage
nxbuild /action=build /project=packages/nexus-packages/graphics/pasjpeg/tests/PasJPEGTests.nxproject
output/pasjpeg-tests/x86_64-linux/PasJPEGTests
nxbuild /action=build /project=../nexus-lab/examples/graphics/jpeg/PasJPEGExamples.nxproject
```

The package needs only the matching NexusFPC RTL; it does not use libjpeg,
Windows units, GUI libraries or the runtime-package SDK. Consumers add `src` to
their unit/include paths. Existing namespace wrappers remain in `namespaced`.
The build selects the portable codec, both transcoding units, constants and the
stream convenience unit. Historical DOS memory managers, assembly alternatives,
the unused `jmemsys` declaration and unfinished `jidct2d` prototype are preserved
as original material but are not supported build inputs. The prototype already
ends mid-unit; its compile error is unrelated to the selected codec.

Examples live centrally in Nexus Lab `examples/graphics/jpeg`. Native tests use
nxtest directly; see [tests/README.md](tests/README.md).
