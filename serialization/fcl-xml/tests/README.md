# FCL XML review regressions

`FCLXML.Review` registers XML regressions with nxtest. Build with Nexus nxbuild
and NexusFPC:

```sh
nxbuild /project=packages/nexus-packages/serialization/fcl-xml/tests/FCLXMLTests.nxproject /action=build
output/fcl-xml-tests/x86_64-linux/FCLXMLTests
```

Keep `FCLXMLTests` and `FCLXMLFixture` together. A case-name fragment filters the
runner, for example `FCLXMLTests 08DOMPrefix`. Each case runs in a separate fixture
with a 30-second deadline and temporary directory. Unix fixtures use their own
process group for cleanup. No helper thread is added.

The project enables range checking and local initialization. Baseline evidence
uses the immutable original package source; fixed evidence uses this package.
The iconv test also has an uninstrumented baseline proof: Windows-1252 bypasses
the character limit. Its positive control reads a valid multibuffer document
containing a non-ASCII character. The iconv case is Unix-specific and explicitly
skips on other hosts. The fixtures otherwise use local files and no external
services or test data downloads.

The retained reader/DOM suites (`readertest`, `extras`, `extras2`) run 36 local
native nxtest cases. `xpathts.pas` is a separate expression runner. Its two namespace-axis
expectations were removed because this feature is explicitly unsupported;
nxtest case 12 verifies rejection. Its two other original failures are fixed
in the implementation. The runner now returns a failing exit status when its
failure count is nonzero. No expected values were weakened to hide those bugs.
The external W3C compliance corpora referenced by the older harnesses are not
bundled and were not run.

Evidence is in Nexus `output/fcl-xml-tests/`: the immutable original tree and
hashes, baseline/fixed build and result logs, package and catalog validation,
and relocation verification. Linux is the executed target; Windows execution
has not been verified. Delphi is outside the Nexus support scope.

## Native behavior suite

From the Nexus root, build this suite with Nexus nxbuild and NexusFPC:

```sh
nxbuild /action=build /project=packages/nexus-packages/serialization/fcl-xml/tests/FCLXMLBehaviorTests.nxproject
```

Configure the matching compiler and RTL in Nexus
`projects/nxbuild/nxbuild.environment.nxscript`.

Run `FCLXMLBehaviorTests` from its output directory.
