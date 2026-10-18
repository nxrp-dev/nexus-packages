# FCL Res

Executable resource readers (RES, COFF/PE, ELF, Mach-O and DFM), resource models,
bitmap/icon/cursor conversion and executable version information. Setup uses
this package for file-version replacement decisions. Runtime units need only
RTL sources; the Lab resource tool additionally uses fcl-base.

Build from the Nexus root with the native Nexus tools:

```sh
output/nxbuild-next/x86_64-linux/nxbuild /action=build /project=packages/nexus-packages/fcl-res/FCLRes.nxpackage
output/nxbuild-next/x86_64-linux/nxbuild /action=build /project=packages/nexus-packages/fcl-res/tests/FCLResTests.nxproject
output/fcl-res-tests/x86_64-linux/FCLResTests
```

The package catalog ID is `NXRP.FCLRes`. Namespace wrappers accompany the flat
units. Test fixtures are generated in memory or temporary files and cleaned up.
Examples live in `nexus-lab/examples/system/resources`.

See [CODE_REVIEW.md](CODE_REVIEW.md) for baseline proofs and verification, and
[Nexus ATTRIBUTIONS.md](../../../ATTRIBUTIONS.md#fcl-res) for provenance/license
attribution. Original source headers and FPC notices remain authoritative.
