# Iconv

Static and dynamic native iconv bindings and encoding conversion.

The sole provider is `packages/nexus-packages/iconvenc`. Original namespace
wrappers/maps and native library declarations remain. Compiler bootstrap and
its stage order are unchanged. Native libraries are supplied by the target OS;
this package supplies Pascal bindings.

From the Nexus checkout:

```sh
nxbuild /action=build /project=packages/nexus-packages/iconvenc/Iconv.nxproject
nxbuild /action=build /project=packages/nexus-packages/iconvenc/tests/IconvTests.nxproject
```

The package recipe uses `Tools.OutputRoot/unix-bindings/iconvenc/<native-target>`;
the tests use `Tools.OutputRoot/unix-bindings-tests/iconvenc/<native-target>`.
The Linux test recipe builds its independent C fixture before the Pascal tests.
Run `IconvTests` there; an optional case name runs one native case in isolation.
Tests create no worker threads or changes to system account databases.

[Saved review](CODE_REVIEW.md) records untouched-source proofs and verification.
[Attribution and provenance](../../../ATTRIBUTIONS.md#unix-iconvenc) are maintained
centrally. Original `COPYING.FPC`, `COPYING.txt` and embedded notices accompany
this package. Namespace support is retained; no dotted-unit migration is included.

The inherited example remains in Nexus Lab `examples/text/encoding`. Linux uses
libc iconv; the static non-Linux binding retains its native iconv dependency.
The Linux dynamic-loader fixture is deliberately built without libc dependencies.
