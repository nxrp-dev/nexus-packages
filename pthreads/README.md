# Pthreads

POSIX thread and synchronization bindings.

The sole provider is `packages/nexus-packages/pthreads`. Original namespace
wrappers/maps and native library declarations remain. Compiler bootstrap and
its stage order are unchanged. Native libraries are supplied by the target OS;
this package supplies Pascal bindings.

From the Nexus checkout:

```sh
nxbuild /action=build /project=packages/nexus-packages/pthreads/Pthreads.nxproject
nxbuild /action=build /project=packages/nexus-packages/pthreads/tests/PthreadsTests.nxproject
```

The package recipe uses `Tools.OutputRoot/unix-bindings/pthreads/<native-target>`;
the tests use `Tools.OutputRoot/unix-bindings-tests/pthreads/<native-target>`.
The Linux test recipe builds its independent C fixture before the Pascal tests.
Run `PthreadsTests` there; an optional case name runs one native case in isolation.
Tests create no worker threads or changes to system account databases.

[Attribution and provenance](../../../ATTRIBUTIONS.md#unix-pthreads) are maintained
centrally. Original `COPYING.FPC`, `COPYING.txt` and embedded notices accompany
this package. Namespace support is retained; no dotted-unit migration is included.

Linux, Android and BSD-family sources retain their platform selection. The
dormant AIX include is preserved but is not selected or claimed as supported.
