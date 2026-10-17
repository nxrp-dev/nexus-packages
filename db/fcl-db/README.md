# FCL DB

Dataset and field support, buffered and memory datasets, JSON and delimited
datasets, DBF, exporters, SQL parsing/generation, data dictionaries and SQLDB
base/pool helpers. Relocated from NexusFPC `packages/fcl-db` on 2026-10-16.
Previously removed SQLDB drivers are not restored.

The [saved review](CODE_REVIEW.md) records 15 reproduced bugs and fixes, plus
one disproved candidate retained as a control. All 199 original files are
preserved in the review archive and hash inventory, including original examples,
test data, namespace wrappers, translations and notices. Licensing and author
credits are in the [canonical attribution record](../../../../ATTRIBUTIONS.md#fcl-db).

`Package.nxscript` registers `NXRP.Database.FCLDB` in both catalogs.
`FCLDB.nxpackage` builds 66 ordinary runtime units from the ten `src` subfolders.
Two obsolete IDE registration units and six alternative translations declaring
the same ordinary unit name remain as historical material outside that build.
Namespace wrappers are preserved for separate consumers.

From the Nexus root, with nxbuild available:

```sh
nxbuild /project=packages/nexus-packages/db/fcl-db/FCLDB.nxpackage /action=build
nxbuild /project=packages/nexus-packages/db/fcl-db/tests/FCLDBTests.nxproject /action=build
output/fcl-db-tests/x86_64-linux/FCLDBTests
nxbuild /action=build /project=packages/nexus-packages/db/fcl-db/tests/FCLDBBehaviorTests.nxproject
```

The recipes use NexusFPC's installed RTL, fcl-base, rtl-objpas, rtl-extra,
pthreads and the relocated fcl-json/fcl-xml packages, with their source
dependencies. A runtime-package SDK is not required for these builds.
Compiler/host settings come from
[`nxbuild.environment.nxscript`](../../../../projects/nxbuild/nxbuild.environment.nxscript).
Runtime outputs go to `output/nxbuild-fcl-db/<target>`.

See [tests/README.md](tests/README.md) for original-source proofs and saved
results. Native Linux validation passes 16 nxtest cases, 943 retained tests
and 28 SQLite consumer tests; cross-platform and live-server limits are in the
review.
