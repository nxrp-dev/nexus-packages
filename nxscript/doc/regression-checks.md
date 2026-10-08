# NexusScript regression checks

These checks protect the language's behavior across compilation, includes,
validation, presentation, and editor updates. They supplement focused tests;
they do not replace reviewing an intentional contract change.

From the repository root:

```powershell
lazbuild -B packages\nexus-packages\nxscript\test\NexusScriptTests.lpi
& .\output\NexusScript\console-tests\x86_64-win64\NexusScriptTests.exe
lazbuild -B projects\ls\nxscript\test\NexusScriptLSTests.lpi
& .\output\NexusScriptLS\console-tests\x86_64-win64\NexusScriptLSTests.exe
```

Both runners use the existing NexusTest cases, fail on errors or unexpected
skips, and enable heap and debug-line checks. The compiler suite is required for
compiler/validation/include/presentation corrections. The language-server suite
is additionally required for changes to shared compiler behavior or editor code.
These are repository verification requirements; no CI toolchain installation was
added by this change.

## Contract cases

| Case | Behavior protected |
| --- | --- |
| `IncludeFileEquivalence` | The same nine-table system in one file or included files has equivalent JSON, validation, and generated output. Only source provenance is removed from the JSON comparison, and the test separately requires the original provenance to differ. |
| `CompleteSQLContract` | Complete generated SQL is compared with a handwritten fixture, including columns, order, an index, and a foreign-key target. Only platform line endings are normalized. |
| `SQLiteEmitterWorkspaceProjection` | The SQLite emitter uses `Nexus`, `Packages`, `NexusScript`, and `NexusLib` definition names plus the `Notes` property name as tables. Definition kinds do not become table names. Generated IDs and actual owner-table relationships preserve structure, while scalar array rows retain value and order. |
| `EmitterFactory` | The registered `json` and `sqlite` names create their corresponding concrete classes through the typed NexusScript emitter factory. |
| `SQLiteEmitterCommandFormat` | `/format=sqlite` resolves through the registered emitter factory and writes a readable SQLite database through the normal command path. |
| `SQLiteEmitterDefinitionArrayNames` | Two definition-valued properties containing the same `Field` kind produce distinct `PrimaryFields` and `AuditFields` tables under the named `Customer` root. Rows retain owner, ordinal, name, and scalar properties; neither `Catalog` nor `Field` becomes a table. |
| `SQLiteEmitterDialectlessSchemaExample` | The dialectless Storm/inForce example derives tables from completed observed structure. Named roots and definitions produce `Storm`, `inForce`, `CoreTypes`, and `StormTypes`; properties produce `Tables` and `Fields`; kind-named `Schema`, `Type`, `Table`, and `Field` tables remain absent. Nested fields reference their actual `Tables` owner. |
| `TargetedIncludeCollections` | Selected definitions and selected language fragments agree, excluded kinds/rules stay absent, and a shared dependency reached through module plus diamond includes contributes once. |
| `IncludeModuleCollections` | A module-only base is not generated independently. Including it exposes it once; a derived field override does not change the base or a reference to the original. Root-name conflicts are also checked with different casing. |
| `StructuralReferenceAliasJSON` | A property referencing another structural-reference property presents the original definition. This is isolated from includes so a failure cannot hide the include assertions. |
| `EmitterFailureAndLifetime` | An emission failure after staging valid content does not alter previous output; the emitter remains usable. Recompilation and destruction of source documents cannot corrupt copied JSON. |
| `ReferenceArrayProjection` | Compilation retains full real targets. JSON alone omits structural arrays recursively, without changing the graph; direct expansion cycles fail emission, not compilation. |
| `InlineReferenceMetadata` | Aliases of named inline array entries retain declared names separately from effective labels and receiving property names. |
| `SQLiteReferenceCycles` | Concrete self/mutual references and aliases save real FK links between the existing authored rows, through both file and stream output. No extra tables are introduced. |
| `SQLiteReferenceFields` | A User table's updated_by field points back to the existing User row. Literal types and numeric-looking text remain separate from reference IDs; aliases retain the same target; dialect/dialectless and file/stream output agree. FK enforcement rejects an invalid target ID. |
| `SQLiteReferenceFailures` | Column collisions, one property targeting different SQL tables, and module-only targets outside the output produce errors instead of discarded links or incomplete stream artifacts. |
| `NexusScript.Live` suite | Shared targets, cycles, complete arrays, immediate alias targets, provenance, independent snapshots, post-session lifetime, and failed-emission cleanup. |
| `IncludedDefinitionRefresh` (LS) | Editing an included overlay changes names and values in dependent analyses; removing all definitions leaves no stale contributions. |
| `IncludedLanguageRefresh` (LS) | Replacing an included rule removes the old rule and updates diagnostics; malformed dependencies fail, and subsequent correction restores clean analysis. |

The SQL expectation is
`test/fixtures/include-collections/SQL.expected.txt`. It was written from the
small fixture's intended schema, not captured from generated output. No test or
helper rewrites it. Changes to the language contract require reviewing the
expected-output diff explicitly, rather than accepting whatever the compiler
currently emits.

To retain the database produced by `SQLiteEmitterWorkspaceProjection` for
inspection, set `NEXUS_SQLITE_REVIEW_DATABASE` to its destination path before
running the suite. Without this variable, the test removes its temporary
database as usual.

The existing individual feature tests continue to cover composition, arrays,
references, targets, discovery, diagnostics, metadata, manifests, and external
data. The cases above protect their interactions.

## Semantic graph versus output policy

The compiled model retains original reference targets rather than cloned JSON
projections. `StructuralDefinition` owns inline structure; `DefinitionValue`
and `SemanticValue` navigate effective semantic data without manufacturing copies.
Definition cycles compile; aliases requiring an uncomputable value do not.
The bounded projection contract and recursion diagnostic belong exclusively to
[JSON presentation](include-presentation.md#reference-projection-boundary).

The SQLite emitter retains its original authored relational projection. The
cycle correction is in common compilation, not an extra compiler-node schema.
Setup's native and UI tests live under `projects/setup/test/`; Forge regression
tests remain unchanged and do not consume Live as part of this work.
