# FCL Registry

Native Windows registry access (`Registry`) and the portable XML registry backend
(`XmlReg`). Windows COM support, Abbrevia ZIP associations and Synapse serial-port
code consume this package. XML emulation remains the portable FCL behavior.

The descriptor is [Package.nxscript](Package.nxscript). From the Nexus root:

```sh
nxbuild /action=build /project=packages/nexus-packages/fcl-registry/FCLRegistry.nxpackage
```

The native recipe uses the configured NexusFPC and its RTL. Consumers add `src`
to their unit/include search paths. Portable XML support also uses relocated
FCL XML, relocated FCL Base and Iconv, plus NexusFPC RTL-ObjPas. Namespace wrappers are
retained for separate dotted-unit consumers.

See the [saved review](CODE_REVIEW.md) for findings and verification limits, and
[tests](tests/NXTEST.md) for direct nxtest instructions. Examples live in Nexus Lab
`examples/system/registry` and `examples/runtime/base`.

Authorship, source revision, relocation evidence and licensing are recorded in
[Nexus attributions](../../../ATTRIBUTIONS.md#fcl-registry). Original license
texts and source notices are retained alongside the package.
