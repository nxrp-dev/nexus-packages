# External-reference validation

Completed October 19, 2026 on Linux x86-64.

## Results

| Check | Result |
| --- | --- |
| NexusScript NXTests | 88 passed; zero failures/errors/skips |
| nxbuild NXTests | 38 passed; zero failures/errors/skips |
| Setup NXTests | 24 passed; zero failures/errors/skips |
| NexusScript and nxbuild CLIs | Rebuilt successfully |
| NexusScript and nxbuild heap tracing | Zero unfreed blocks in the test runners |
| Diff whitespace checks | Passed in both repositories |

The final NexusScript run used the newly rebuilt nxbuild. All builds used the
standard promoted NexusFPC compiler and the actual source/test files. No patched
source copies or altered bootstrap stages were used. Native Windows execution
was not performed.

Evidence folder: `/media/kcollins/dev/worktree/nexusscript-external-wilnhw7j`. Raw logs are under `logs/`; `source-hashes.sha256`
identifies the tested Pascal sources. The untouched initial package snapshot is
`nxscript-before.tar.gz`. Validation command wrappers and the exact SQLite native
command are saved alongside the logs. Build products, temporary fixtures and the
matching SQLite runtime are outside source. The temporary environment OutputRoot
change was restored byte for byte to the checked-in file after every build.

Starting revisions:

- Nexus: `e4fc726a2290700d2b532571efdb2b8a61f51c5d`.
- nexus-packages: `0f94315030630c83228ac181b751544af316f9f5`.

## Baseline findings and resolution

The original test recipe selected Windows only. Its native target and unit paths
were aligned with the existing working nxbuild test recipe. With implementation
code still untouched, 64 of 75 tests passed.

Three NXTests failed while checking generated files: `CommandTemplateManifest`,
`CommandExternalDataManifest`, and `SchemaGenerationMockData`. They appended
Windows backslashes to Linux paths. Generated files existed under normal slash
paths. The actual tests and their cleanup now use portable suffixes. Three SQLite
test output filenames also now use temporary paths instead of a source output
folder. The expected payloads and assertions were retained.

Eight SQLite tests loaded the system runtime, which was older than the required
3.53.4 binding. Validation now uses the repository's actual `sqlite3.c`, built
with its checked-in Linux config and feature defines, through `LD_LIBRARY_PATH`.
No binding checks were weakened and no system installation was changed. All
original 75 NXTests pass with those test-environment corrections.

## New coverage

Thirteen `NexusScript.External` NXTests cover generic selected Targets, lazy
reads, custom/dotted identities, empty versus unresolved values, case sensitivity,
source ranges, internal aliases, arrays, selected-target immutability, desired
state and explicit result events, duplicate assignments, filtering/composition,
import ownership and shadowing, reentrant evaluation, dialect source forms,
deferred constraints, revalidation and artifact boundaries.

Review found two defects in the new implementation. Both were demonstrated by
failing NXTests in `review-regressions-before-tests.log` before correction:

- `ArrayAliasConstraints`: validation annotated an array projection copy while
  Live correctly shared the original entries. Array validation now annotates the
  semantic entries that Live accesses.
- `ValidationReplacement`: a second validation retained the earlier deferred
  checks. Constraints now retain their validating subject, and revalidation
  replaces that subject's checks without removing checks from imported subjects.

Both regressions pass in the final 88-test run. `NXBuild.Dependencies.ExternalPublisherPaths`
checks real dependency publications constructed from `$TargetOS`, `$TargetCPU`
and a custom `$Profile`, across two target selections. Existing compiler-target
conflict and publication-selection tests still pass.

The nxbuild log also contains deliberately induced tool exit codes 23 and 37.
They belong to passing executor failure-propagation NXTests, not failed builds
of this implementation.

## API boundary

See [external references](external-references.md) for the event API and lifecycle.
The core supplies selected Targets generically; processors supply other values
and consume desired results explicitly. JSON/SQLite reject unmaterialized
external semantics. Product-specific persistence and event-handler integration
remain processor responsibilities. Language-server feature work remains deferred.
