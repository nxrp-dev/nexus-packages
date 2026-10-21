# FCL JSON review regressions

`FCLJSON.Review` registers regression cases with nxtest. Three follow-up cases
replace obsolete retained-suite snapshots and cover two additional proven generator bugs.

From the Nexus root, build with nxbuild:

```sh
nxbuild /project=packages/nexus-packages/serialization/fcl-json/tests/FCLJSONTests.nxproject /action=build
```

Configure the compiler, SDK and source locations in
`projects/nxbuild/nxbuild.environment.nxscript`. Both executables are written
to `output/fcl-json-tests/<target>/`. Keep `FCLJSONTests` and `FCLJSONFixture`
together. The project enables range checks and `-gt` to make the uninitialized
generator local visible without depending on previous stack contents.

Run with the matching installed NexusFPC compiler and RTL paths, for example:

```sh
NXTEST_FPC=/media/kcollins/dev/toolchain/nexus-fpc/x86_64-linux/current/bin/ppcx64 \
NXTEST_RTL=/media/kcollins/dev/toolchain/nexus-fpc/x86_64-linux/current/units/x86_64-linux/rtl \
output/fcl-json-tests/x86_64-linux/FCLJSONTests
```

The original generator case compiles twelve units: three scalar/complex-array examples
with load/save disabled, load only, save only, and both enabled. Its compiler
must match the SDK and the JSON units alongside the fixture. Missing compiler
or RTL settings produce an explicit prerequisite skip.

Cases 12 and 13 compile and run 24 array programs across the same four load/save
settings. They check object arrays, type suffixes, nested object/scalar arrays,
mixed scalar/object-array fields, JSON values and destruction of all owned
objects. Case 14 checks true/false Boolean types and spellings, cached flushes,
write-through and reopened values. The nine invalid retained-suite tests were
removed; the saved review records each diagnosis. Delphi-specific output was
inspected against its documented API but not compiled on this Linux host.

The YAML case requires Python with PyYAML. It defaults to `python3` on Unix and
`python` on Windows; `NXTEST_PYTHON` selects another executable. It compares
independently parsed YAML with the input JSON, including scalar types and keys.
Missing Python/PyYAML produces an explicit prerequisite skip. These tools are
test prerequisites and are not dependencies of the runtime package.

Passing part of a case name filters the suite, for example
`FCLJSONTests 07Unsigned`. Each case runs in a separate fixture process with a
30-second parent deadline; external tools get ten seconds per invocation. Unix
probes use their own session so the parent can clean up any remaining child
tools. Temporary configuration files, generated units and YAML stay inside the
probe directory and are removed afterward. No helper thread is introduced.

Verified on x86_64 Linux with NexusFPC 3.3.1:

- Untouched source: **11 failed, 0 passed, 0 skipped**.
- The eleven original corrections: **11 passed, 0 failed/errors, 0 skipped**,
  also passing without range checks or `-gt`.
- Follow-up generator cases 12 and 13 both fail before their corrections;
  the Boolean replacement already passes.
- Current complete suite: **14 passed, 0 failed/errors, 0 skipped**.
- All 13 regular runtime units compile through `FCLJSON.nxproject`.
- All retained suites pass: JSON 415 tests (one existing ignore), generator 77,
  configuration 9 and INI 28, with zero failures/errors.

Evidence is in Nexus `output/fcl-json-tests/`, including raw regression results,
untouched source hashes, build logs, `upstream-comparison.json`, follow-up
snapshots in `remaining-before/` and results in `upstream-remaining-final/`.
Windows and other target executions have not been verified.

## Native behavior suite

From the Nexus root, build this suite with Nexus nxbuild and NexusFPC:

```sh
nxbuild /action=build /project=packages/nexus-packages/serialization/fcl-json/tests/FCLJSONBehaviorTests.nxproject
```

Configure the matching compiler and RTL in Nexus
`projects/nxbuild/nxbuild.environment.nxscript`.

Run `FCLJSONBehaviorTests` from its output directory.
