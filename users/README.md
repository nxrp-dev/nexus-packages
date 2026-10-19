# Users

Unix account, group and Linux shadow-record bindings.

The sole provider is `packages/nexus-packages/users`. Original namespace
wrappers/maps and native library declarations remain. Compiler bootstrap and
its stage order are unchanged. Native libraries are supplied by the target OS;
this package supplies Pascal bindings.

From the Nexus checkout:

```sh
nxbuild /action=build /project=packages/nexus-packages/users/Users.nxpackage
nxbuild /action=build /project=packages/nexus-packages/users/tests/UsersTests.nxproject
```

The package recipe uses `Tools.OutputRoot/unix-bindings/users/<native-target>`;
the tests use `Tools.OutputRoot/unix-bindings-tests/users/<native-target>`.
The Linux test recipe builds its independent C fixture before the Pascal tests.
Run `UsersTests` there; an optional case name runs one native case in isolation.
Tests create no worker threads or changes to system account databases.

[Saved review](CODE_REVIEW.md) records untouched-source proofs and verification.
[Attribution and provenance](../../../ATTRIBUTIONS.md#unix-users) are maintained
centrally. Original `COPYING.FPC`, `COPYING.txt` and embedded notices accompany
this package. Namespace support is retained; no dotted-unit migration is included.

The inherited example remains in Nexus Lab `examples/system/users`. The `crypth`
binding additionally needs the target crypt library; shadow records are Linux-only.
