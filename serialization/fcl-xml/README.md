# FCL XML

Free Pascal XML/DOM components relocated from NexusFPC `packages/fcl-xml` on
2026-10-16. All 71 original files were preserved before local corrections.
The [saved review](CODE_REVIEW.md) records 14 reproduced findings and fixes.
Upstream authorship, source revisions, licenses and relocation evidence are in
[the canonical Nexus attributions](../../../../ATTRIBUTIONS.md#fcl-xml).
Original headers, notices, namespace wrappers, examples and license texts remain
with the package. `buildfclxml.pas` is retained historical material and is not a
Nexus build entry point.

[Package.nxscript](Package.nxscript) registers `NXRP.Serialization.FCLXML` in both
package catalogs. [FCLXML.nxproject](FCLXML.nxproject) compiles 20 common runtime
units and the target encoding adapter: `xmliconv` on Linux and
`xmliconv_windows` on Win64. It uses NexusFPC RTL/RTL-ObjPas and the relocated FCL Base package;
the Unix adapter additionally uses iconvenc. No runtime-package SDK is required.
The namespaced wrappers are retained for separate consumers and are not built
alongside ordinary unit names.

From the Nexus root:

```sh
nxbuild /project=packages/nexus-packages/serialization/fcl-xml/FCLXML.nxproject /action=build
nxbuild /project=packages/nexus-packages/serialization/fcl-xml/tests/FCLXMLTests.nxproject /action=build
output/fcl-xml-tests/x86_64-linux/FCLXMLTests
```

Configure the native compiler and source locations in
[`nxbuild.environment.nxscript`](../../../../projects/nxbuild/nxbuild.environment.nxscript).
Package output is `output/nxbuild-fcl-xml/<target>/`; source consumers use `src`.
See [test instructions](tests/README.md) for regression and retained-suite details.

The XPath namespace axis and incomplete XML object-streaming operations raise
explicit errors. They previously returned empty results or printed messages
while dropping data. This relocation does not invent implementations for those
unsupported features. The deprecated `xmlcfg` unit remains marked deprecated;
`xmlconf` is the supported Unicode configuration implementation.
