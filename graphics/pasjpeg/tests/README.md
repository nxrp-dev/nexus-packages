# PasJPEG verification

Build `PasJPEGTests.nxproject` with Nexus nxbuild and the matching NexusFPC/RTL.
Run `PasJPEGTests` from `output/pasjpeg-tests/<native-target>`.

The direct nxtest cases exercise both public conversion APIs and completion
callbacks, nil callbacks, bitmap gaps/trailers, indexed output, baseline and
progressive JPEG, integer/fast/floating-point DCT and reduced-size decoding.
There is no FPCUnit dependency or bridge. No original test suite was present.

For optional independent interoperability checks with Pillow installed:

```sh
python3 packages/nexus-packages/graphics/pasjpeg/tests/VerifyInterop.py \
  output/pasjpeg-tests/x86_64-linux/PasJPEGFixture \
  output/pasjpeg-review/interop
```

The helper generates its own gradient images, compares encoded/decoded pixels
with Pillow's codec, and saves images and measurements only under output. No
downloaded image fixtures or additional runtime dependencies are needed.

The untouched source at NexusFPC revision
`bfd5d2156b01f1213b3fa16e3b3fde38588c9d5d` is identified by
`../review/baseline-hashes.json`. Local proof uses the exact snapshot in ignored
Nexus `output/pasjpeg-review/untouched`. Core-only tests run against that snapshot.
The public convenience unit cannot compile unchanged, so its runtime cases run
against a separately documented compilation-only repair, before the callback
and bitmap-offset fixes are applied. The same cases run against the final source.
