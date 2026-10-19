# FCL JSON

Free Pascal's JSON package, moved from NexusFPC `packages/fcl-json` into
`nexus-packages` on 2026-10-15. Source, namespaced wrappers, examples, upstream
tests and the existing code review were preserved unchanged at relocation.
Subsequent nxtest regressions reproduced and corrected all eleven findings in
the [saved review](CODE_REVIEW.md).

[FCLJSON.nxproject](FCLJSON.nxproject) builds all 13 runtime units as static
NexusFPC units. It does not require a runtime-package SDK. Namespaced wrappers are retained for separate consumers and
are not compiled alongside the ordinary unit names.

From the Nexus repository root:

```sh
output/nxbuild-next/x86_64-linux/nxbuild /action=plan /project=packages/nexus-packages/serialization/fcl-json/FCLJSON.nxproject
output/nxbuild-next/x86_64-linux/nxbuild /action=build /project=packages/nexus-packages/serialization/fcl-json/FCLJSON.nxproject
```

On Windows, use `output/nxbuild-next/x86_64-win64/nxbuild.exe` with the same
arguments. Configure the compiler, RTL and NexusFPC source paths in the shared
[`nxbuild.environment.nxscript`](../../../../projects/nxbuild/nxbuild.environment.nxscript).
Outputs go to `output/nxbuild-fcl-json/<target>`; consumers add that directory
to their unit search path. Source consumers use this package's `src` directory.

The runtime units use the relocated `NXRP.FCLBase` package and NexusFPC's `rtl-objpas` sources.
This move does not migrate those packages. The retained upstream behavior tests now use nxtest directly, alongside the review
regressions. See [FPCUnit retirement report](../../../../docs/migrations/fpcunit/README.md).

Upstream authorship, source revision, relocation evidence and licensing are
recorded in the canonical [Nexus attributions](../../../../ATTRIBUTIONS.md#fcl-json).
The original [JSON API notes](src/README.txt) remain available.

## Review regressions

The [nxtest project](tests/FCLJSONTests.nxproject) builds a console runner and
isolated fixture. All fourteen cases pass on Linux, including independent YAML
parsing, compilation of 36 generated Pascal units and execution of 24 array
programs that verify values and object ownership. See
[test instructions](tests/README.md) for prerequisites and commands.

All 13 runtime units and the nxbuild/NexusScript CLI consumers compile with the
corrections. All retained suites now pass, with one existing Linux ignore.
Follow-up diagnosis removed nine obsolete tests and fixed two additional
generator cleanup bugs hidden by their layout assertions. Details and
before/after evidence are in the saved review.

## Relocation verification

Verified on 2026-10-15 with the installed native x86-64 Linux NexusFPC and LLVM:

- The nxbuild recipe compiled all 13 runtime units. The package descriptor,
  both catalogs and the updated dependent descriptors passed validation.
- The retained `testjson` runner executed 415 tests with zero errors or failures;
  one line-ending test was ignored by its existing Linux guard.
- `testjson2code` executed 85 tests with eight failures. An isolated export of
  the pre-move committed source produced the same eight failure messages with
  the same compiler and dependencies. The move preserves those existing failures.
- All 54 relocated files matched their original SHA-256 hashes.

Logs and the code-generation baseline comparison are in Nexus
`output/fcl-json-migration`. The Windows package build and NexusFPC's Win64
Forge release-tool build were not run on this Linux host.
