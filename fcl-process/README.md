# FCL Process

Free Pascal's external-process, pipe and local IPC support, moved from NexusFPC
`packages/fcl-process` into `nexus-packages/fcl-process` on 2026-10-15.
All 53 original files, including source, platform backends, namespace wrappers,
examples, assets and upstream tests, were preserved byte for byte at relocation.

The [code review](CODE_REVIEW.md) was saved alongside the original package
before relocation. Subsequent nxtest regressions reproduced and fixed eleven
findings on Linux. Three Windows findings remain open pending execution of
their Windows cases. See the [regression instructions](test/README.md) for
build commands and verification limits.

## Source consumption

Add `src` to the consumer's unit search path. Select the appropriate include
directories for `process.inc`, `pipes.inc` and `simpleipc.inc`:

- Unix: `src/unix`.
- Win32/Win64: `src/win` for process and pipe implementations, and `src/winall`
  for the IPC implementation.

`processbody.inc` is shared by the process units. Compile Windows service support
only for Windows. The package's `fcl-base` dependency remains in NexusFPC;
individual units have narrower dependencies. Namespace wrappers are retained
for separate consumers and are not compiled alongside ordinary unit names.

The intrinsic descriptor is [Package.nxscript](Package.nxscript). NexusForge,
nxbuild and BotHost consume the relocated process/pipe source through their
project search paths. This package is not a compiler/RTL bootstrap input or a
staged release-tool dependency.

Upstream authorship, source revision, relocation evidence and licensing are
recorded in the canonical [Nexus attributions](../../../ATTRIBUTIONS.md#fcl-process).
The retained [process notes](src/process.txt) document the upstream API.
