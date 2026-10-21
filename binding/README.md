# Nexus Binding

`TNXBindingSource` connects current source values to bound consumers through
non-owning CORBA interfaces. The package is independent of fpGUI and concrete
data sources.

See [binding contracts](docs/contracts.md) for navigation, pending edits,
conversion, validation and lifetime rules.

From the Nexus repository root:

```sh
nxbuild /action=build /project=packages/nexus-packages/binding/tests/NexusBindingTests.nxproject
```

Run the generated programs from the output directories resolved by their projects.

Only the tests depend on NexusTest; production units use the Free Pascal runtime.
