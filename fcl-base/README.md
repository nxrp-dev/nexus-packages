# FCL Base

Nexus's maintained Free Component Library base package. This directory is the
sole source provider; its former NexusFPC `packages/fcl-base` directory is
removed. Package identity: `NXRP.FCLBase`.

The package retains streams, Contnrs, INI files, CSV, expression evaluation,
templates, observers, URI handling, encoders, formatting writers, synchronization
and platform utilities. Contnrs remains intact. Existing flat units and dotted
wrappers retain their current selection rules.

Build from the Nexus root with the configured native NexusFPC/RTL:

```sh
nxbuild /action=build /project=packages/nexus-packages/fcl-base/FCLBase.nxproject
nxbuild /action=build /project=packages/nexus-packages/fcl-base/tests/FCLBaseTests.nxproject
nxbuild /action=build /project=packages/nexus-packages/fcl-base/tests/FCLBaseReviewTests.nxproject
```

The package recipe builds all 45 runtime units. It uses the compiler's RTL,
the retained RTL-ObjPas units, and Pthreads for Unix synchronization bindings.
Source consumers select the applicable `src/<OS>`, `src/<PascalPlatform>` and
`src/dummy` include directories. Native build products go to the configured
external worktree output root.

`FCLBaseTests` runs the existing native nxtest suite. `FCLBaseReviewTests` runs
the relocation regressions; an optional case name selects one case for isolated
baseline reproduction. Test vectors are small checked-in constants, and runtime
temporary files are removed in `finally` blocks. These are ordinary compiled
unit builds; no compiler bootstrap stage or runtime-package SDK is introduced.

Examples and demonstrations remain centralized in Nexus Lab
`examples/runtime/base`. Test-only fixtures remain in `tests`. See
[the relocation review](CODE_REVIEW.md), [the tests](tests/NXTEST.md), and
[central attribution and provenance](../../../ATTRIBUTIONS.md#fcl-base).
Original notices, the FPC linking exception, and the LGPL license text accompany
the source. Individual broader license grants and the original ASCII85 public
domain declaration remain in their source headers.
