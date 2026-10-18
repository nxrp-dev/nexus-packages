# Nexus HashLib4Pascal

`NXRP.HashLib4Pascal` packages the upstream Hlp API directly. It supplies digests,
HMACs, checksums and KDFs for ordinary Nexus libraries, applications and tools.
Compiler metadata processing and PasZLib do not depend on it.

This is the sole maintained HashLib source tree, in the main Nexus package
repository. The former External Packages location has been removed. Retained
FPC RSA/ECDSA/PEM/OTP/UUID/NTLM services now consume this provider directly;
the superseded MD/SHA/HMAC/CRC/FNV providers and their assembly includes are gone.

The complete runtime import contains 144 Pascal units and 135 includes, with
upstream SIMD defaults intact and PPL disabled. The original MIT license and
README remain under `external/hashlib4pascal`. Authors, revision, import evidence
and support-unit licensing are in the
[central attribution record](../../../ATTRIBUTIONS.md#hashlib4pascal).
See [the source/integration review](CODE_REVIEW.md) for verified results and limits.

From Nexus on native Linux, build and run the source comparison suite:

```sh
output/nxbuild-next/x86_64-linux/nxbuild /action=build /project=packages/nexus-packages/hashlib4pascal/tests/HashLib4PascalTests.nxproject
output/HashLib4PascalTests/x86_64-linux/HashLib4PascalTests
```

This compiles all 144 units and exercises known answers, binary boundaries,
incremental updates, clone/reset, explicit encoding, files and streams. It is a
source build; it does not establish runtime-package ownership or ABI behavior.
All 26 cases pass, including the migrated fourteen RFC 2202 HMAC cases and useful
SHA-1/CRC vectors. The FPC-derived HMAC tests retain their original license texts
under `tests`; the runtime import remains MIT. See the central attribution record
for both owners.

For a compiled runtime package, configure `HashLibLinux.SDKDirectory` in
`HashLib4Pascal.Build.Config.nxscript` with a matching native Linux runtime-package
SDK. An installed compiler/RTL alone is insufficient. The empty default is
intentional: no native SDK is present on the current host. Then run:

```sh
output/NexusForge-next/x86_64-linux/nxforge /input=packages/nexus-packages/hashlib4pascal/HashLib4Pascal.Forge.nxscript /targets=Build:Package,TargetOS:linux,TargetCPU:x86_64
output/NexusForge-next/x86_64-linux/nxforge /input=packages/nexus-packages/hashlib4pascal/HashLib4Pascal.Forge.nxscript /targets=Build:Tests,TargetOS:linux,TargetCPU:x86_64
```

`Build:Package` prepares, compiles and publishes `HashLib4Pascal.nxpl` under
`output/HashLib4Pascal/packages`. Inspect its actual contained-unit metadata:
nxrtl must retain ownership of its exported foundation units; only unowned
standard support units may be incorporated with their original FPC notices.
An ownership collision must be resolved before accepting a provider build.

`Build:Tests` consumes that published package through
`RequiredPackages: [nxrtl, HashLib4Pascal]`, using only tests and nxtest source
paths. It builds, publishes and runs both ordinary and smart-linked consumers.
Executables run from their matching work directories; published bundles are in
`output/HashLib4Pascal/tests` and `smart-tests`.

For the source-hidden check, build the provider first, temporarily move the
`external/hashlib4pascal/HashLib` directory out of the checkout, and run only
`Build:Tests` into clean consumer work directories. Restore the directory
afterward. No Hlp source directory or loose Hlp NXU belongs in those consumer
directories. Also verify rejection of absent providers and mismatched generations
with the selected SDK. These compiled-package checks remain unexecuted on the
current host; the source suite passing does not replace them.

Metadata storage now uses `NXPM0002`. Rebuild the compiler/Forge reader, SDK and
packages together before using this recipe; old `NXPM0001` envelopes are rejected
with rebuild advice. The existing compiler build sequence is unchanged.
