# FCL Image verification

`FCLImageTests.nxproject` builds the nxtest runner and isolated fixture.
There are 18 review cases. A fixture has a 30-second deadline and its own process
group on Unix; failures, crashes and heap errors cannot be mistaken for success.
HeapTrc catches allocation overruns/leaks. Range checks exercise QOI modular
arithmetic explicitly. The Linux FreeType case skips only if the runtime itself
cannot be loaded independently; it passes on the verified Linux host.

The retained barcode suite now registers 17 native nxtest cases. All pass.
Its old FPCUnit runner was retired and archived.
Retained and review suites use separate output directories.

From the Nexus root on Linux:

```sh
python3 packages/nexus-packages/graphics/fcl-image/tests/VerifyReview.py baseline
python3 packages/nexus-packages/graphics/fcl-image/tests/VerifyReview.py fixed
python3 packages/nexus-packages/graphics/fcl-image/tests/VerifyReview.py plain
```

The harness defaults to the current sibling NexusFPC sources and the native
x86_64 Linux toolchain under `../../toolchain/nexus-fpc/x86_64-linux/current`
relative to the Nexus root. Optional second and third arguments override the
SDK root and NexusFPC source root. It verifies all archived original hashes,
refuses to overwrite a differing baseline, compiles current regression sources
against the selected package source, then saves results under
`output/fcl-image-tests/<mode>`. Baseline returns failure intentionally (0/18
passing). `baseline-plain` provides additional original-source evidence without
range/local instrumentation; the QOI arithmetic case needs range checks to
expose its unchecked narrowing. Heap guards remain active in every mode.

Original examples and assets are kept unchanged. `FCLImageExamples.nxproject`
compiles all 13 examples. Run examples from a scratch directory with needed
assets copied there; several examples produce files in their current directory.
The review records the executed drawing, barcode, QR, codec and font examples
and independent output checks. No Lazarus tooling or Delphi validation is used.

## Native behavior suite

From the Nexus root, build this suite with Nexus nxbuild and NexusFPC:

```sh
nxbuild /action=build /project=packages/nexus-packages/graphics/fcl-image/tests/FCLImageBehaviorTests.nxproject
```

Configure the matching compiler and RTL in Nexus
`projects/nxbuild/nxbuild.environment.nxscript`.

Run `FCLImageBehaviorTests` from its output directory.
