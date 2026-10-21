# Native FCL Base tests

From the Nexus root, use Nexus nxbuild and the configured matching NexusFPC/RTL:

```sh
nxbuild /action=build /project=packages/nexus-packages/fcl-base/tests/FCLBaseTests.nxproject
nxbuild /action=build /project=packages/nexus-packages/fcl-base/tests/FCLBaseReviewTests.nxproject
```

`FCLBaseTests` runs the 426 migrated native cases. `FCLBaseReviewTests` runs the
27 relocation cases with range, overflow, I/O and assertion checks. Run each
executable from its configured external worktree output directory. The review
runner accepts one optional case name, for example `CacheGrow`, to reproduce a
case independently against the untouched source snapshot.

Tests register directly with nxtest. There is no FPCUnit bridge, helper runner
or external discovery. The ASCII85 constants come from Python's standard-library
encoder. Test-only runtime files use the host temporary directory (override
`TMPDIR` when desired) and are removed in `finally` blocks.

NexusFPC's
[central nxtest guide](../../../../../nexus-fpc/tests/NXTEST.md) links this suite
as an external owner.
