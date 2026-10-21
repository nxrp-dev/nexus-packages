# Native FCLRegistryTests

From the Nexus root, use Nexus nxbuild with the configured NexusFPC:

```sh
nxbuild /action=build /project=packages/nexus-packages/fcl-registry/tests/FCLRegistryTests.nxproject
output/fcl-registry-tests/x86_64-linux/FCLRegistryTests
```

The Linux recipe compiles the direct nxtest runner, its bounded child fixture,
and the original standalone `tregistry2` behavioral program. Run the latter from
its generated output directory. There is no FPCUnit bridge.

All test builds enable bounds checks and `XMLRegfile_in_CurDir`. The runner and
child cases use generated output directories for registry XML, including cleanup;
no test deletes the user's normal application registry configuration. The
production package recipe does not enable that test-only define.

The nine existing direct nxtest cases are retained;
24 focused cases cover the ten fixes plus the selected-key deletion control.
Native Windows registry execution requires a Windows toolchain/host and is not
claimed by the Linux checks.

The consumer checks are a separate direct nxtest runner. First build the Lab
examples; then, from Nexus:

```sh
nxbuild /action=build /project=../nexus-lab/examples/system/registry/RegistryExamples.nxproject
output/fcl-registry-tests/x86_64-linux/FCLRegistryExampleTests ../nexus-lab/output/RegistryExamples/x86_64-linux
```

Those four cases reject failed exits and diagnostic failures from the actual
examples. Two reproduced missing Unix string-conversion manager imports before
the consumer fix; both Unicode examples are passing controls. Building/running
the 33 package tests does not require Lab.
